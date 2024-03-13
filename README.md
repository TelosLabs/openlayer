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
  "YOUR_PROJECT_ID",
  "YOUR_TARFILE_PATH"
)

development_pipeline.post_data("This is a commit message")
```

The tarfile must follow a specific directory format

staging
├── commit.yaml
├── model
│   └── model_config.yaml
└── validation
    ├── dataset.csv
    └── dataset_config.yaml

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/TelosLabs/openlayer.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
