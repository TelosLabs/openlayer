# frozen_string_literal: true

module Openlayer
  class DevelopmentPipeline
    attr_reader :client, :workspace_id, :project_id, :data_tarfile_path, 
      :s3_presigned_body

    def initialize(client, workspace_id, project_id, data_tarfile_path)
      @client = client
      @workspace_id = workspace_id
      @project_id = project_id
      @data_tarfile_path = data_tarfile_path
    end

    def post_data(commit_message:)
      post_presigned_url
      post_staging_data
      post_commit_message(commit_message: commit_message)
    end

    private
    
    def post_presigned_url
      
      @s3_presigned_body = handle_response client.connection.post(
        "storage/presigned-url?objectName=staging&workspaceId=#{workspace_id}&version=0.1.0a25"
      )
    end

    def post_staging_data
      s3_conn = Faraday.new(url: s3_presigned_body["url"]) do |f|
        f.request :multipart
        f.adapter :net_http
      end

      handle_response s3_conn.post("/", staging_data_payload)
    end

    def staging_data_payload
      s3_presigned_body["fields"].merge!(
        {
          "file" => Faraday::Multipart::FilePart.new(data_tarfile_path, "application/x-tar")
        }
      )
    end

    def post_commit_message(commit_message: )
      payload = {
        "storageUri": s3_presigned_body["storageUri"],
        "commit": {"message": commit_message}
      }

      handle_response client.connection.post("projects/#{project_id}/versions", payload)
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
  end
end