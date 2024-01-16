# frozen_string_literal: true

RSpec.describe Openlayer do
  it "has a version number" do
    expect(Openlayer::VERSION).not_to be nil
  end

  describe Openlayer::Client do
    it "should have a client" do
      client = Openlayer::Client.new(api_key: "api_key", adapter: :test)
      expect(client).to be_a(Openlayer::Client)
    end
  end

  describe Openlayer::InferencePipeline do
    it "should have a pipeline" do
      client = Openlayer::Client.new(api_key: "api_key", adapter: :test)
      pipeline = client.inference_pipeline("inference_pipeline_id")
      expect(pipeline).to be_a(Openlayer::InferencePipeline)
    end
  end
end
