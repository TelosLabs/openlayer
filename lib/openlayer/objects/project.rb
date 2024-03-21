# frozen_string_literal: true

require "fileutils"
require "find"
require "yaml"
require "pry"

module Openlayer
  class Project < Object
    class Error < StandardError; end
    class NotFoundError < StandardError; end
    class TarFileNotFoundError < StandardError; end

    class CommitLengthError < StandardError
      def message
        "Commit message must be between 1 and 140 characters"
      end
    end

    attr_reader :client, :workspace_id,
                :data_tarfile_path, :s3_presigned_body,
                :commit_message, :project_path

    REQUIRED_TARFILE_STRUCTURE = [
      "./staging/commit.yaml",
      "./staging/validation/dataset_config.yaml",
      "./staging/validation/dataset.csv",
      "./staging/model/model_config.yaml"
    ].freeze

    COMMIT_LENGTH = (1..140).freeze

    def self.from_response(client, response)
      attributes_first_project = handle_response(response)&.dig("items")&.first
      raise NotFoundError if attributes_first_project.nil?

      new(client, attributes_first_project)
    end

    def initialize(client, attributes)
      @client = client
      super(attributes)
      @data_tarfile_path = "#{Dir.home}/.openlayer/#{id}_staging.tar"
      @project_path = "#{Dir.home}/.openlayer/#{id}"
      init_staging_directories
    end

    def add_dataset(file_path:, dataset_config: nil, dataset_config_file_path: nil)
      raise ArgumentError, "dataset config is required" if dataset_config.nil? && dataset_config_file_path.nil?

      copy_file(file_path, "staging/validation/dataset.csv")
      copy_or_create_config(dataset_config,
                            dataset_config_file_path,
                            "staging/validation/dataset_config.yaml")
    end

    def add_model(model_config: nil, model_config_file_path: nil)
      raise ArgumentError, "model config is required" if model_config.nil? && model_config_file_path.nil?

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

    def commit(message)
      raise CommitLengthError unless COMMIT_LENGTH.include? message.length

      @commit_message = message
      commit_hash = {
        "date": DateTime.now.strftime("%a %b %d %H:%M:%S %Y"),
        "message": message
      }
      write_hash_to_file(commit_hash, "staging/commit.yaml")
    end

    def push
      create_and_validate_tar_file
      s3_client = create_s3_client
      s3_client.post(s3_payload)
      client.load_project_version(id: id, payload: version_payload)
    end

    private

    def init_staging_directories
      FileUtils.mkdir_p(File.join(project_path, "staging"))
      FileUtils.mkdir_p(File.join(project_path, "staging/validation"))
      FileUtils.mkdir_p(File.join(project_path, "staging/model"))
    end

    def copy_or_create_config(config_hash, config_file_path, destination)
      if config_file_path.nil?
        write_hash_to_file(config_hash, destination)
      else
        copy_file(config_file_path, destination)
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

    def create_s3_client
      @s3_presigned_body = client.presigned_url(workspace_id: workspace_id, object_name: "staging")
      S3PresignedClient.new(s3_presigned_body)
    end

    def create_and_validate_tar_file
      TarFileHelper.create_tar_from_folders([File.join(project_path, "staging")], data_tarfile_path)
      validate_tarfile(data_tarfile_path)
    end

    def validate_tarfile(file_path)
      raise TarFileNotFoundError unless File.exist?(file_path)

      TarFileHelper.validate_structure(file_path, REQUIRED_TARFILE_STRUCTURE)
    end

    def s3_payload
      {
        "file" => Faraday::Multipart::FilePart.new(data_tarfile_path, "application/x-tar")
      }
    end

    def version_payload
      {
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
  end
end
