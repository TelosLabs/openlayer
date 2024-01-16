# frozen_string_literal: true

require "openlayer"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  def stub_response
    double("response", status: 200, body: { "message" => "success" })
  end

  def stub_request(path:, response:, method: :get)
    Faraday::Adapter::Test::Stubs.new do |stub|
      stub.get(path) { |_env| response }
    end
  end
end
