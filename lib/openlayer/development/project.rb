# frozen_string_literal: true

module Openlayer
  class Project
    attr_reader :client, :workspace_id, :project_id, :data_tarfile_path,
                :s3_presigned_body, :s3_client, :commit_message

    REQUIRED_TARFILE_STRUCTURE = [
      "./staging/commit.yaml",
      "./staging/validation/dataset_config.yaml",
      "./staging/validation/dataset.csv",
      "./staging/model/model_config.yaml"
    ].freeze

    def initialize(client, workspace_id, project_id)
      @client = client
      @workspace_id = workspace_id
      @project_id = project_id
      init_staging_dir
      init_s3_connection
    end

    def add_dataset(file_path:, dataset_config: nil, dataset_config_file_path: nil)
      if dataset_config.nil? && dataset_config_file_path.nil?
        raise Error, "Dataset config or dataset config file path is required"
      end

      raise Error, "File path is required" if file_path.nil?

      copy_file_to_staging(file_path, "validation/dataset.csv")
      if !dataset_config_file_path.nil?
        copy_file_to_staging(dataset_config_file_path, "validation/dataset_config.yaml")
      else
        write_hash_to_staging(dataset_config, "validation/dataset_config.yaml")
      end
    end

    def add_model(model_config: nil, model_config_file_path: nil)
      if model_config.nil? && model_config_file_path.nil?
        raise Error, "Model config or model config file path is required"
      end

      if !model_config_file_path.nil?
        copy_file_to_staging(model_config_file_path, "model/model_config.yaml")
      else
        write_hash_to_staging(model_config, "model/model_config.yaml")
      end
    end

    def status
      puts "Staging Area:"
      system("ls -R #{project_path}/staging")
    end

    def commit(message:)
      raise Error, "Commit message must be between 1 and 140 characters" if message.length > 140 || message.length < 1

      @commit_message = message
      commit_hash = {
        "date": commit_date,
        "message": message
      }
      write_hash_to_staging(commit_hash, "commit.yaml")
    end

    def push
      tar_staging_data
      push_staging_data_to_s3
      Version.new(client, version_body.dig("commit", "projectVersionId"))
    end

    def restart_s3_connection
      init_s3_connection
    end

    private

    def project_path
      "#{Dir.home}/.openlayer/#{project_id}"
    end

    def init_staging_dir
      Dir.mkdir("#{Dir.home}/.openlayer") unless Dir.exist?("#{Dir.home}/.openlayer")
      Dir.mkdir("#{project_path}") unless Dir.exist?("#{project_path}")
      Dir.mkdir("#{project_path}/staging") unless Dir.exist?("#{project_path}/staging")
      Dir.mkdir("#{project_path}/staging/validation") unless Dir.exist?("#{project_path}/staging/validation")
      Dir.mkdir("#{project_path}/staging/model") unless Dir.exist?("#{project_path}/staging/model")
    end

    def init_s3_connection
      version = "0.1.0a25"
      objectName = "staging"
      @s3_presigned_body = handle_response client.connection.post(
        "storage/presigned-url?objectName=#{objectName}&workspaceId=#{workspace_id}&version=#{version}"
      )
      @s3_client = S3PresignedClient.new(s3_presigned_body)
    end

    def copy_file_to_staging(file_path, destination)
      system("cp #{file_path} #{project_path}/staging/#{destination}")
    end

    def write_hash_to_staging(hash, destination)
      File.open("#{project_path}/staging/#{destination}", "w") do |file|
        file.write hash.to_yaml
      end
    end

    def commit_date
      current_time = DateTime.now
      current_time.strftime("%a %b %d %H:%M:%S %Y")
    end

    def tar_staging_data
      @data_tarfile_path = "#{Dir.home}/.openlayer/#{project_id}_staging.tar"
      system("tar -czf #{data_tarfile_path} -C #{project_path}/ .")
      validate_tarfile(data_tarfile_path)
    end

    def push_staging_data_to_s3
      s3_client.post(staging_data_payload)
    end

    def staging_data_payload
      {
        "file" => Faraday::Multipart::FilePart.new(data_tarfile_path, "application/x-tar")
      }
    end

    def version_body
      handle_response client.connection.post("projects/#{project_id}/versions", push_commit_payload)
    end

    def push_commit_payload
      payload = {
        "storageUri": s3_presigned_body["storageUri"],
        "commit": { "message": commit_message }
      }
    end

    def handle_response(response)
      message = response.body["error"]
      case response.status
      when 200
        response.body
      when 401
        raise Error, message
      when 404
        raise Error, message
      when 422
        raise Error, message
      when 500
        raise Error, message
      when 200..299
        response.body
      else
        raise Error, message
      end
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
