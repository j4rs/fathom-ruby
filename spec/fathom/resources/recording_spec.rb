# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Recording do
  describe ".resource_path" do
    it "returns the correct API path" do
      expect(described_class.resource_path).to eq("recordings")
    end
  end

  describe ".get_summary" do
    it "fetches summary for a recording" do
      summary_response = {
        "summary" => {
          "template_name" => "general",
          "markdown_formatted" => "## Summary\nDiscussed Q1 goals."
        }
      }
      stub_fathom_request(:get, "recordings/123456789/summary", response_body: summary_response)

      summary = described_class.get_summary(123_456_789)
      expect(summary).to be_a(Hash)
      expect(summary["template_name"]).to eq("general")
    end

    it "supports async mode with destination_url" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/recordings/123456789/summary?destination_url=https://example.com/webhook")
             .to_return(status: 200, body: { destination_url: "https://example.com/webhook" }.to_json)

      result = described_class.get_summary(123_456_789, destination_url: "https://example.com/webhook")
      expect(result).to be_a(Hash)
      expect(stub).to have_been_requested
    end
  end

  describe ".get_transcript" do
    it "fetches transcript for a recording" do
      transcript_response = {
        "transcript" => [
          {
            "speaker" => {
              "display_name" => "Alice Johnson",
              "matched_calendar_invitee_email" => "alice@example.com"
            },
            "text" => "Let's begin.",
            "timestamp" => "00:00:15"
          }
        ]
      }
      stub_fathom_request(:get, "recordings/123456789/transcript", response_body: transcript_response)

      transcript = described_class.get_transcript(123_456_789)
      expect(transcript).to be_an(Array)
      expect(transcript.first["speaker"]["display_name"]).to eq("Alice Johnson")
    end

    it "supports async mode with destination_url" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/recordings/123456789/transcript?destination_url=https://example.com/webhook")
             .to_return(status: 200, body: { destination_url: "https://example.com/webhook" }.to_json)

      result = described_class.get_transcript(123_456_789, destination_url: "https://example.com/webhook")
      expect(result).to be_a(Hash)
      expect(stub).to have_been_requested
    end
  end

  describe ".all" do
    it "raises NotImplementedError" do
      expect { described_class.all }.to raise_error(NotImplementedError, /not supported/)
    end
  end

  describe ".retrieve" do
    it "raises NotImplementedError" do
      expect { described_class.retrieve("rec_123") }.to raise_error(NotImplementedError, /not supported/)
    end
  end
end
