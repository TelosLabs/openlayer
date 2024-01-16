# frozen_string_literal: true

require "faraday"
require "faraday_middleware"

module Openlayer
  class Client
    BASE_URL = "https://api.openlayer.com/v1/"

    attr_reader :api_key, :adapter

    def initialize(api_key:, adapter: Faraday.default_adapter, stubs: nil)
      @api_key = api_key
      @adapter = adapter
      @stubs = stubs
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

    def inference_pipeline(inference_pipeline_id)
      InferencePipeline.new(self, inference_pipeline_id)
    end
  end
end
