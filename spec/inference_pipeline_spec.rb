# frozen_string_literal: true

RSpec.describe Openlayer::InferencePipeline do
  let(:inference_pipeline_id) { "pipeline_id" }
  let(:stub) do
    stub_request(path: "inference-pipelines/#{inference_pipeline_id}/data-stream", response: stub_response,
                 method: :post)
  end
  let(:client) { Openlayer::Client.new(api_key: "api_key", adapter: :test, stubs: stub) }
  let(:pipeline) { client.inference_pipeline(inference_pipeline_id) }

  describe "#stream_data" do
    let(:attributes) { { "rows" => [{}], "config" => {} } }
    let(:response) { double("response", status: 200, body: { "message" => "success" }) }

    before do
      allow(client).to receive_message_chain(:connection, :post).and_return(response)
    end

    it "sends a POST request to the correct endpoint with the given attributes" do
      expect(client).to receive_message_chain(:connection, :post).with(
        "inference-pipelines/#{inference_pipeline_id}/data-stream", body: attributes
      )
      pipeline.stream_data(**attributes)
    end

    it "returns true if the response status is 200" do
      expect(pipeline.stream_data(**attributes)).to eq(true)
    end
  end
end
