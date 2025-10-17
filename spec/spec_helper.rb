# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter "/spec/"
end

require "fathom"
require "webmock/rspec"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true

  config.default_formatter = "doc" if config.files_to_run.one?

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Reset configuration before each test
  config.before(:each) do
    Fathom.reset!
    Fathom.api_key = "test_api_key"
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end

# Test helper methods
module FathomTestHelpers
  def stub_fathom_request(method, path, response_body: {}, status: 200, headers: {})
    default_headers = {
      "Content-Type" => "application/json",
      "RateLimit-Limit" => "60",
      "RateLimit-Remaining" => "59",
      "RateLimit-Reset" => "60"
    }.merge(headers)

    stub_request(method, "https://api.fathom.ai/external/v1/#{path}")
      .with(
        headers: {
          "X-Api-Key" => "test_api_key",
          "Content-Type" => "application/json",
          "Accept" => "application/json"
        }
      )
      .to_return(
        status: status,
        body: response_body.to_json,
        headers: default_headers
      )
  end

  def stub_rate_limited_request(method, path)
    stub_request(method, "https://api.fathom.ai/external/v1/#{path}")
      .to_return(
        status: 429,
        body: { error: "Rate limit exceeded" }.to_json,
        headers: {
          "Content-Type" => "application/json",
          "RateLimit-Limit" => "60",
          "RateLimit-Remaining" => "0",
          "RateLimit-Reset" => "5"
        }
      )
  end
end

RSpec.configure do |config|
  config.include FathomTestHelpers
end
