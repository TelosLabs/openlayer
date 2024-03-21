# frozen_string_literal: true

require "faraday"
require "faraday/multipart"

module Openlayer
  class Client
    BASE_URL = "https://api.openlayer.com/v1/"

    attr_reader :api_key, :adapter

    def initialize(api_key:, adapter: Faraday.default_adapter, stubs: nil)
      @api_key = api_key
      @adapter = adapter
      @stubs = stubs
    end

    def inference_pipeline(inference_pipeline_id)
      InferencePipeline.new(self, inference_pipeline_id)
    end

    def load_project(name:)
      Project.from_response self, connection.get("projects", project_search_params(name: name))
    end

    def presigned_url(object_name: nil, workspace_id: nil)
      handle_response connection.post(
        "storage/presigned-url?objectName=staging", presigned_url_params(object_name: object_name,
                                                                         workspace_id: workspace_id)
      )
    end

    def load_project_version(id:, payload: {})
      ProjectVersion.from_response self, connection.post("projects/#{id}/versions", payload)
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = BASE_URL
        conn.request :authorization, "Bearer", api_key
        conn.request :json
        conn.response :json, content_type: "application/json"
        conn.adapter adapter, @stubs
      end
    end

    private

    def project_search_params(name:)
      { version: "0.1.0a25", name: name }
    end

    def presigned_url_params(object_name: nil, workspace_id: nil)
      { "objectName": object_name, "workspaceId": workspace_id, version: "0.1.0a25" }.compact
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
