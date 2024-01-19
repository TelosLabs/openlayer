# frozen_string_literal: true

module Openlayer
  class InferencePipeline
    attr_reader :client, :inference_pipeline_id

    def initialize(client, inference_pipeline_id)
      @client = client
      @inference_pipeline_id = inference_pipeline_id
    end

    def stream_data(body = {})
      handle_response client.connection.post("inference-pipelines/#{inference_pipeline_id}/data-stream", body)
      true
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
      else
        raise Error, message
      end
      response
    end
  end
end
