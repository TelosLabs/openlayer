# frozen_string_literal: true

require "ostruct"
module Openlayer
  class Object
    def initialize(attributes)
      @attributes = OpenStruct.new(attributes)
    end

    def method_missing(method, *args, &block)
      method = snake_to_camel(method.to_s)
      attribute = @attributes.send(method, *args, &block)
      attribute.is_a?(Hash) ? Object.new(attribute) : attribute
    end

    def respond_to_missing?(_method, _include_private = false)
      true
    end

    private

    def snake_to_camel(snake_str)
      snake_str.split("_").each_with_index.map do |part, index|
        index.zero? ? part : part.capitalize
      end.join
    end
  end
end
