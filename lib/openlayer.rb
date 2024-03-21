# frozen_string_literal: true

require_relative "openlayer/version"

module Openlayer
  autoload :Client, "openlayer/client"
  autoload :Error, "openlayer/error"
  autoload :Object, "openlayer/object"
  autoload :InferencePipeline, "openlayer/inference_pipeline"
  autoload :Version, "openlayer/development/version"
  autoload :S3PresignedClient, "openlayer/services/s3_presigned_client"
  autoload :TarFileHelper, "openlayer/services/tar_file_helper"

  # Classes used to return a nicer object wrapping the response data
  autoload :Project, "openlayer/objects/project"
end
