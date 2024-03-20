# frozen_string_literal: true

RSpec.describe Openlayer::Project do
  let(:workspace_id) { "workspace_id" }
  let(:project_id) { "project_id" }
  let(:client) { Openlayer::Client.new(api_key: "api_key", adapter: :test) }
  let(:project) { client.create_or_load_project(workspace_id, project_id) }

  describe "#add_dataset" do
    let(:file_path) { "dataset.csv" }
    let(:dataset_config) { { "name" => "dataset" } }

    it "raises an error if file_path is nil" do
      expect { project.add_dataset(file_path: nil) }.to raise_error(Openlayer::Error, "File path is required")
    end

    it "raises an error if dataset_config and dataset_config_file_path are nil" do
      expect { project.add_dataset(file_path: file_path) }.to raise_error(Openlayer::Error, "Dataset config or dataset config file path is required")
    end
  end

  describe "#add_model" do
    let(:model_config) { { "name" => "model" } }

    it "raises an error if model_config and model_config_file_path are nil" do
      expect { project.add_model }.to raise_error(Openlayer::Error, "Model config or model config file path is required")
    end
  end

  describe "#commit" do
    let(:message) { "commit message" }

    it "raises an error if the message is longer than 140 characters" do
      expect { project.commit(message: "a" * 141) }.to raise_error(Openlayer::Error, "Commit message must be between 1 and 140 characters")
    end

    it "raises an error if the message is shorter than 1 character" do
      expect { project.commit(message: "") }.to raise_error(Openlayer::Error, "Commit message must be between 1 and 140 characters")
    end
  end

  describe "#status" do
    it "prints the contents of the staging area" do
      expect { project.status }.to output("Staging Area:\n").to_stdout
    end
  end

  describe "#commit_date" do
    it "returns the current date" do
      expect(project.commit_date).to eq(Time.now.strftime("%Y-%m-%d"))
    end
  end


  describe "#push" do
    let(:response) { double("response", status: 200, body: { "message" => "success" }) }

    before do
      allow(client).to receive_message_chain(:connection, :post).and_return(response)
    end

    it "sends a POST request to the correct endpoint with the given attributes" do
      expect(client).to receive_message_chain(:connection, :post).with(
        "workspaces/#{workspace_id}/projects/#{project_id}/push", body: { commit_message: "commit message" }
      )
      project.push(commit_message: "commit message")
    end

    it "returns true if the response status is 200" do
      expect(project.push(commit_message: "commit message")).to eq(true)
    end
  end
end
