# frozen_string_literal: true

module Openlayer
  class DevelopmentVersion
    attr_reader :client, :project_version_id, :version_body

    def initialize(client, project_version_id)
      @client = client
      @project_version_id = project_version_id
      refresh
    end

    def status
      version_body.fetch("status")
    end

    def status_message
      version_body.fetch("statusMessage")
    end

    def failing_test_count
      version_body.fetch("failingGoalCount")
    end

    def passing_test_count
      version_body.fetch("passingGoalCount")
    end

    def total_test_count
      version_body.fetch("totalGoalCount")
    end

    def print_status_report
      puts "Status: #{status}"
      puts "Status Message: #{status_message}" unless status_message.nil?
    end

    def print_test_report
      puts "Failing Test Count: #{failing_test_count}"
      puts "Passing Test Count: #{passing_test_count}"
      puts "Total Test Count: #{total_test_count}"
    end

    def to_dict
      version_body
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
      get_version
    end

    private

    def get_version
      @version_body = handle_response client.connection.get("versions/#{project_version_id}")
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
    end
  end
end
