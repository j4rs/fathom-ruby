# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom do
  describe ".configure" do
    it "allows configuration via block" do
      described_class.configure do |config|
        config.api_key = "my_key"
        config.debug = true
        config.auto_retry = false
      end

      expect(described_class.api_key).to eq("my_key")
      expect(described_class.debug).to be true
      expect(described_class.auto_retry).to be false
    end
  end

  describe ".api_key" do
    it "raises error when not configured" do
      described_class.reset!
      expect { described_class.api_key }.to raise_error(Fathom::Error, /not configured/)
    end

    it "returns the configured API key" do
      described_class.api_key = "test_key"
      expect(described_class.api_key).to eq("test_key")
    end
  end

  describe ".auto_retry" do
    it "defaults to true" do
      described_class.reset!
      expect(described_class.auto_retry).to be true
    end

    it "can be set to false" do
      described_class.auto_retry = false
      expect(described_class.auto_retry).to be false
    end
  end

  describe ".max_retries" do
    it "defaults to 3" do
      expect(described_class.max_retries).to eq(3)
    end

    it "can be customized" do
      described_class.max_retries = 5
      expect(described_class.max_retries).to eq(5)
    end
  end

  describe ".debug" do
    it "defaults to false" do
      expect(described_class.debug).to be false
    end

    it "can be enabled" do
      described_class.debug = true
      expect(described_class.debug).to be true
    end
  end

  describe ".debug_http" do
    it "defaults to false" do
      expect(described_class.debug_http).to be false
    end

    it "can be enabled" do
      described_class.debug_http = true
      expect(described_class.debug_http).to be true
    end
  end

  describe ".reset!" do
    it "resets all configuration to defaults" do
      described_class.api_key = "test"
      described_class.auto_retry = false
      described_class.max_retries = 10
      described_class.debug = true
      described_class.debug_http = true

      described_class.reset!

      expect { described_class.api_key }.to raise_error(Fathom::Error)
      expect(described_class.auto_retry).to be true
      expect(described_class.max_retries).to eq(3)
      expect(described_class.debug).to be false
      expect(described_class.debug_http).to be false
    end
  end

  describe ".log" do
    it "outputs message when debug is enabled" do
      described_class.debug = true
      expect { described_class.log("test message") }.to output("[Fathom] test message\n").to_stdout
    end

    it "does not output when debug is disabled" do
      described_class.debug = false
      expect { described_class.log("test message") }.not_to output.to_stdout
    end
  end

  describe ".log_http" do
    it "outputs message when debug_http is enabled" do
      described_class.debug_http = true
      expect { described_class.log_http("HTTP request") }.to output("[Fathom HTTP] HTTP request\n").to_stdout
    end

    it "does not output when debug_http is disabled" do
      described_class.debug_http = false
      expect { described_class.log_http("HTTP request") }.not_to output.to_stdout
    end
  end
end
