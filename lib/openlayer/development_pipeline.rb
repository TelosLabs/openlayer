# frozen_string_literal: true

module Openlayer
  class DevelopmentPipeline
    attr_reader :client, :workspace_id, :project_id, :data_tarfile_path, 
      :s3_presigned_body, :s3_client, :commit_message

    REQUIRED_TARFILE_STRUCTURE = [
      "staging/commit.yaml",
      "staging/validation/dataset_config.yaml",
      "staging/validation/dataset.csv",
      "staging/model/model_config.yaml"
    ].freeze

    def initialize(client, workspace_id, project_id)
      @client = client
      @workspace_id = workspace_id
      @project_id = project_id
      init_s3_connection
    end

    def add_tarfile(data_tarfile_path)
      validate_tarfile(data_tarfile_path)
      @data_tarfile_path = data_tarfile_path
    end

    def commit(message:)
      stage_data
      @commit_message = message
    end

    def push
      handle_response client.connection.post("projects/#{project_id}/versions", push_commit_payload)
    end

    def restart_s3_connection
      init_s3_connection
    end

    private
    
    def init_s3_connection
      version = "0.1.0a25"
      objectName = "staging"
      @s3_presigned_body = handle_response client.connection.post(
        "storage/presigned-url?objectName=#{objectName}&workspaceId=#{workspace_id}&version=#{version}"
      )
      @s3_client = S3PresignedClient.new(s3_presigned_body)
    end

    def stage_data
      s3_client.post(staging_data_payload)
    end

    def staging_data_payload
      {
        "file" => Faraday::Multipart::FilePart.new(data_tarfile_path, "application/x-tar")
      }
    end

    def push_commit_payload
      payload = {
        "storageUri": s3_presigned_body["storageUri"],
        "commit": {"message": commit_message}
      }
    end

    def handle_response(response)
      message = response.body["error"]
      case response.status
      when 200
        return response.body
      when 401
        raise Error, message
      when 404
        raise Error, message
      when 422
        raise Error, message
      when 500
        raise Error, message
      when 200..299
        return response.body
      else
        raise Error, message
      end
      response
    end

    def validate_tarfile(data_tarfile_path)
      validate_tarfile_exists(data_tarfile_path)
      validate_tarfile_structure(data_tarfile_path)
    end

    def validate_tarfile_exists(data_tarfile_path)
      raise Error, "File not found" unless File.exist?(data_tarfile_path)
    end

    def validate_tarfile_structure(data_tarfile_path)
      tarfile_structure = []
      begin
        Gem::Package::TarReader.new(Zlib::GzipReader.open(data_tarfile_path)).each do |entry|
          tarfile_structure << entry.full_name
        end
      rescue Zlib::GzipFile::Error => e
        stacktrace = e.backtrace.join("\n")
        LOGGER.error("ERROR: #{e.message}\n #{stacktrace}")
        return nil
      end

      REQUIRED_TARFILE_STRUCTURE.each do |required_file|
        raise Error, "Missing file: #{required_file}" unless tarfile_structure.include?(required_file)
      end
    end
  end
end