# frozen_string_literal: true

require "pry"
RSpec.describe Openlayer::Project do
  let(:client) { Openlayer::Client.new(api_key: ENV.fetch("OPENLAYER_API_KEY")) }
  let(:project) { client.load_project(name: "RailsApp") }

  describe "#load_project" do
    xit "loads the project" do
      expect(project).to be_a(Openlayer::Project)
      expect(project.name).to eq("RailsApp")
    end

    xit "pushes the dataset and model to the staging area" do
      project.add_dataset(file_path: "spec/fixtures/staging/validation/dataset.csv",
                          dataset_config_file_path: "spec/fixtures/staging/validation/dataset_config.yaml")
      project.add_model(model_config_file_path: "spec/fixtures/staging/model/model_config.yaml")
      expect(project.status).to include("staging/validation/dataset.csv")
      expect(project.status).to include("staging/model/model_config.yaml")
      expect(project.status).to include("staging/validation/dataset_config.yaml")
    end

    xit "commits the dataset and model to the project" do
      project.add_dataset(file_path: "spec/fixtures/staging/validation/dataset.csv",
                          dataset_config_file_path: "spec/fixtures/staging/validation/dataset_config.yaml")
      project.add_model(model_config_file_path: "spec/fixtures/staging/model/model_config.yaml")
      project.commit("Initial commit")
      project.push
    end
  end
end
