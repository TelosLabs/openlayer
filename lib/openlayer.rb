# frozen_string_literal: true

require_relative "openlayer/version"

module Openlayer
  autoload :Client, "openlayer/client"
  autoload :Error, "openlayer/error"
  autoload :InferencePipeline, "openlayer/inference_pipeline"
  autoload :DevelopmentPipeline, "openlayer/development_pipeline"
  autoload :S3PresignedClient, "openlayer/services/s3_presigned_client"
  # Your code goes here...
end
