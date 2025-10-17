# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Meeting do
  let(:meeting_attributes) do
    {
      "title" => "Weekly Standup",
      "recording_id" => 123_456_789,
      "default_summary" => {
        "template_name" => "general",
        "markdown_formatted" => "## Summary\nDiscussed project updates."
      },
      "transcript" => [
        {
          "speaker" => { "display_name" => "John Doe" },
          "text" => "Meeting transcript...",
          "timestamp" => "00:05:32"
        }
      ],
      "calendar_invitees" => [
        { "name" => "John Doe", "email" => "john@example.com" }
      ],
      "action_items" => [
        { "description" => "Follow up on proposal", "completed" => false }
      ]
    }
  end
  let(:meeting) { described_class.new(meeting_attributes) }

  describe ".resource_path" do
    it "returns the correct API path" do
      expect(described_class.resource_path).to eq("meetings")
    end
  end

  describe ".all" do
    it "fetches all meetings" do
      stub_fathom_request(:get, "meetings", response_body: { items: [meeting_attributes] })

      meetings = described_class.all
      expect(meetings).to be_an(Array)
      expect(meetings.first).to be_a(described_class)
      expect(meetings.first.title).to eq("Weekly Standup")
    end

    it "supports query parameters" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/meetings?include_summary=true&limit=10")
             .to_return(status: 200, body: { items: [] }.to_json,
                        headers: { "Content-Type" => "application/json" })

      described_class.all(include_summary: true, limit: 10)
      expect(stub).to have_been_requested
    end
  end

  describe "#recording_id" do
    it "returns the recording ID" do
      expect(meeting.recording_id).to eq(123_456_789)
    end
  end

  describe "#summary" do
    it "returns the default_summary object" do
      expect(meeting.summary).to be_a(Hash)
      expect(meeting.summary["template_name"]).to eq("general")
    end
  end

  describe "#transcript" do
    it "returns the transcript array" do
      expect(meeting.transcript).to be_an(Array)
      expect(meeting.transcript.first["text"]).to eq("Meeting transcript...")
    end
  end

  describe "#fetch_summary" do
    it "fetches summary via Recording API" do
      summary_response = { "summary" => { "template_name" => "general" } }
      stub_fathom_request(:get, "recordings/123456789/summary", response_body: summary_response)

      summary = meeting.fetch_summary
      expect(summary).to be_a(Hash)
    end

    it "returns nil when no recording_id" do
      meeting_without_recording = described_class.new({ "title" => "Test" })
      expect(meeting_without_recording.fetch_summary).to be_nil
    end
  end

  describe "#fetch_transcript" do
    it "fetches transcript via Recording API" do
      transcript_response = { "transcript" => [{ "text" => "Hello" }] }
      stub_fathom_request(:get, "recordings/123456789/transcript", response_body: transcript_response)

      transcript = meeting.fetch_transcript
      expect(transcript).to be_an(Array)
    end

    it "returns nil when no recording_id" do
      meeting_without_recording = described_class.new({ "title" => "Test" })
      expect(meeting_without_recording.fetch_transcript).to be_nil
    end
  end

  describe "#recording?" do
    it "returns true when recording_id exists" do
      expect(meeting.recording?).to be true
    end

    it "returns false when recording_id is nil" do
      meeting_without_recording = described_class.new({ "title" => "Test" })
      expect(meeting_without_recording.recording?).to be false
    end
  end

  describe "#participants" do
    it "returns the calendar_invitees array" do
      expect(meeting.participants).to be_an(Array)
      expect(meeting.participants.first["name"]).to eq("John Doe")
    end

    it "returns empty array when no participants" do
      meeting_without_participants = described_class.new({ "title" => "Test" })
      expect(meeting_without_participants.participants).to eq([])
    end
  end

  describe "#action_items" do
    it "returns the action items array" do
      expect(meeting.action_items).to be_an(Array)
      expect(meeting.action_items.first["description"]).to eq("Follow up on proposal")
    end
  end
end
