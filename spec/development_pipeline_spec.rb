# frozen_string_literal: true

RSpec.describe Openlayer::DevelopmentPipeline do
  let(:workspace_id) { "workspace_id" }
  let(:project_id) { "project_id" }
  let(:data_tarfile_path) { "staging.tar" }
  let(:stub) do
    stub_request(path: "storage/presigned-url?objectName=staging&workspaceId=#{workspace_id}&version=0.1.0a25",
                 response: stub_response, method: :post)
  end
  let(:client) { Openlayer::Client.new(api_key: "api_key", adapter: :test, stubs: stub) }
  let(:pipeline) { client.development_pipeline(workspace_id, project_id, data_tarfile_path) }

  describe "#post_data" do
    let(:commit_message) { "commit_message" }
    let(:response) { double("response", status: 200, body: { "message" => "success" }) }

    before do
      allow(client).to receive_message_chain(:connection, :post).and_return(response)
      allow(client).to receive_message_chain(:connection, :post).with("projects/#{project_id}/versions", anything)
    end

    it "sends a POST request to the correct endpoint with the given attributes" do
      expect(client).to receive_message_chain(:connection, :post).with(
        "storage/presigned-url?objectName=staging&workspaceId=#{workspace_id}&version=0.1.0a25"
      )
      expect(client).to receive_message_chain(:connection, :post).with("projects/#{project_id}/versions", anything)
      pipeline.post_data(commit_message: commit_message)
    end
  end
end
