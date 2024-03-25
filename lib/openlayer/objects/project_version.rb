# frozen_string_literal: true

module Openlayer
  class ProjectVersion < Object
    attr_reader :client, :project_version_id, :all_attributes_hash

    alias :failing_test_count :failing_goal_count
    alias :passing_test_count :passing_goal_count
    alias :total_test_count :total_goal_count

    def self.from_response(client, response)
      attributes = handle_response(response)
      new(client, attributes)
    end

    def initialize(client, attributes)
      @client = client
      super(attributes)
      @project_version_id = commit.projectVersionId
    end

    def print_status_report
      puts "Status: #{status}"
      puts "Status Message: #{status_message}" unless status_message.nil?
    end

    def print_test_report
      puts "Failing Test Count: #{failing_goal_count}"
      puts "Passing Test Count: #{passing_goal_count}"
      puts "Total Test Count: #{total_goal_count}"
    end

    def to_h
      @attributes.to_h
    end

    def wait_for_completion(timeout: 300, interval: 10)
      start_time = Time.now
      while Time.now - start_time < timeout
        refresh
        break if status == "completed" || status == "failed"

        sleep interval
      end
    end

    def refresh
      @attributes = OpenStruct.new handle_response client.connection.get("versions/#{project_version_id}")
    end

    private

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
