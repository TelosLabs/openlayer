# frozen_string_literal: true

require "fileutils"
require "find"

module Openlayer
  class Project < Object
    class CommitLengthError < StandardError
      def message
        "Commit message must be between 1 and 140 characters"
      end
    end

    attr_reader :client, :workspace_id, :project_id,
                :data_tarfile_path, :s3_presigned_body, :s3_client,
                :commit_message

    REQUIRED_TARFILE_STRUCTURE = [
      "./staging/commit.yaml",
      "./staging/validation/dataset_config.yaml",
      "./staging/validation/dataset.csv",
      "./staging/model/model_config.yaml"
    ].freeze

    COMMIT_LENGTH = (1..140).freeze

    def self.from_response(client, response)
      attributes_first_project = handle_response(response)&.dig("items")&.first
      raise Error, "Project not found" if attributes_first_project.nil?

      new(client, attributes_first_project)
    end

    def initialize(client, attributes)
      @client = client
      super(attributes)
      init_staging_directories
    end

    def add_dataset(file_path:, dataset_config:, dataset_config_file_path:)
      copy_file(file_path, "staging/validation/dataset.csv")
      copy_or_create_config(dataset_config,
                            dataset_config_file_path,
                            "staging/validation/dataset_config.yaml")
    end

    def add_model(model_config:, model_config_file_path:)
      copy_or_create_config(model_config,
                            model_config_file_path,
                            "staging/model/model_config.yaml")
    end

    def status
      puts "Staging Area:"
      Find.find(File.join(project_path, "/staging")) do |path|
        puts path if File.file?(path)
      end
    end

    def commit(message:)
      raise CommitLengthError unless COMMIT_LENGTH.include? message.length

      @commit_message = message
      commit_hash = {
        "date": DateTime.now.strftime("%a %b %d %H:%M:%S %Y"),
        "message": message
      }
      write_hash_to_file(commit_hash, "staging/commit.yaml")
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

    def init_staging_directories
      FileUtils.mkdir_p(File.join(project_path, "staging"))
      FileUtils.mkdir_p(File.join(project_path, "staging/validation"))
      FileUtils.mkdir_p(File.join(project_path, "staging/model"))
    end

    def copy_or_create_config(dataset_config, dataset_config_file_path, destination)
      if dataset_config_file_path.nil?
        copy_file(dataset_config_file_path, destination)
      else
        write_hash_to_file(dataset_config, destination)
      end
    end

    def copy_file(file_path, destination)
      FileUtils.copy(file_path, File.join(project_path, destination))
    end

    def write_hash_to_file(hash, destination)
      File.open(File.join(project_path, destination), "w") do |file|
        file.write hash.to_yaml
      end
    end

    def init_s3_connection
      @s3_presigned_body = client.presigned_url(workspace_id: workspace_id, object_name: "staging")
      @s3_client = S3PresignedClient.new(s3_presigned_body)
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

    def self.handle_response(response)
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
