# Openlayer
Openlayer is a Ruby gem that provides a wrapper for the Openlayer HTTP API. It allows you to connect to Openlayer and interact with its features. Please note that this gem is currently in the early stages of development.


## Installation
Install the gem and add to the application's Gemfile by executing:

    $ bundle add openlayer

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install openlayer

## Usage

### Inference Monitoring Mode
```ruby
client = Openlayer::Client.new(api_key: "YOUR_OPENLAYER_API_KEY")
inference_pipeline = client.inference_pipeline("YOUR_INFERENCE_PIPELINE_ID")
inference_pipeline.stream_data(
    {
        rows: [...],
        config: {...}
    }
)
```

### Development Mode for CI/CD
```ruby
client = Openlayer::Client.new(api_key: "YOUR_OPENLAYER_API_KEY")
development_pipeline = client.development_pipeline(
  "YOUR_WORKSPACE_ID",
  "YOUR_PROJECT_ID"
)

development_pipeline.add_dataset(file_path: "DATASET_FILE_PATH", dataset_config_file_path: "DATASET_CONFIG_FILE_PATH")
development_pipeline.add_model(model_config_file_path: "MODEL_CONFIG_PATH")
development_pipeline.commit(message: "This is a commit message")
version = development_pipeline.push

version.wait_for_completion(timeout: 500)
version.print_test_report

if version.failing_test_count > 0:
    puts "Failing pipeline due to failing goals."
    exit(1)
```

- Check the example in `examples/staging` for what the YAMLs look like.
- Check the [Dataset Config](https://docs.openlayer.com/how-to-guides/write-dataset-configs/llm-dataset-config) and the [Model Config](https://docs.openlayer.com/how-to-guides/write-model-configs/llm-config) docs on Openlayer to see additional attributes for the configs.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TelosLabs/openlayer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
