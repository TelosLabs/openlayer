# frozen_string_literal: true

require_relative "openlayer/version"

module Openlayer
  autoload :Client, "openlayer/client"
  autoload :Error, "openlayer/error"
  autoload :InferencePipeline, "openlayer/inference_pipeline"
  autoload :DevelopmentPipeline, "openlayer/development_pipeline"
  # Your code goes here...
end
