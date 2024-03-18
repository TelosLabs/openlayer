# frozen_string_literal: true

module Openlayer
  class S3PresignedClient
    attr_reader :presigned_url, :payload_fields, :s3_conn

    def initialize(presigned_url)
      @presigned_url = presigned_url
      @payload_fields = presigned_url["fields"]
      @s3_conn = Faraday.new(url: presigned_url["url"]) do |f|
        f.request :multipart
        f.adapter :net_http
      end
    end

    def post(data)
      handle_response @s3_conn.post("/", merge_fields(data))
    end

    private

    def merge_fields(data)
      payload_fields.merge!(data)
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
