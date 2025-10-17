# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Webhook do
  let(:webhook_attributes) do
    {
      "id" => "webhook_123",
      "url" => "https://example.com/webhook",
      "active" => true,
      "secret" => "whsec_12345",
      "triggered_for" => %w[my_recordings shared_external_recordings],
      "include_transcript" => true,
      "include_summary" => true,
      "include_action_items" => false,
      "include_crm_matches" => false
    }
  end
  let(:webhook) { described_class.new(webhook_attributes) }

  describe ".resource_path" do
    it "returns the correct API path" do
      expect(described_class.resource_path).to eq("webhooks")
    end
  end

  describe ".all" do
    it "fetches all webhooks" do
      stub_fathom_request(:get, "webhooks", response_body: { items: [webhook_attributes] })

      webhooks = described_class.all
      expect(webhooks).to be_an(Array)
      expect(webhooks.first).to be_a(described_class)
      expect(webhooks.first.url).to eq("https://example.com/webhook")
    end
  end

  describe ".retrieve" do
    it "fetches a single webhook" do
      stub_fathom_request(:get, "webhooks/webhook_123", response_body: { data: webhook_attributes })

      webhook = described_class.retrieve("webhook_123")
      expect(webhook.id).to eq("webhook_123")
      expect(webhook.url).to eq("https://example.com/webhook")
    end
  end

  describe ".create" do
    it "creates a new webhook" do
      stub_fathom_request(:post, "webhooks", response_body: { data: webhook_attributes })

      webhook = described_class.create(
        url: "https://example.com/webhook",
        include_transcript: true,
        include_summary: true
      )
      expect(webhook).to be_a(described_class)
      expect(webhook.url).to eq("https://example.com/webhook")
    end
  end

  describe "#delete" do
    it "deletes the webhook" do
      stub_fathom_request(:delete, "webhooks/webhook_123", status: 204)

      expect(webhook.delete).to be true
    end
  end

  describe "#url" do
    it "returns the webhook URL" do
      expect(webhook.url).to eq("https://example.com/webhook")
    end
  end

  describe "#include_transcript?" do
    it "returns true when transcript is included" do
      expect(webhook.include_transcript?).to be true
    end

    it "returns false when transcript is not included" do
      webhook = described_class.new({ "id" => "webhook_123", "include_transcript" => false })
      expect(webhook.include_transcript?).to be false
    end
  end

  describe "#include_summary?" do
    it "returns true when summary is included" do
      expect(webhook.include_summary?).to be true
    end

    it "returns false when summary is not included" do
      webhook = described_class.new({ "id" => "webhook_123", "include_summary" => false })
      expect(webhook.include_summary?).to be false
    end
  end

  describe "#include_action_items?" do
    it "returns false when action items are not included" do
      expect(webhook.include_action_items?).to be false
    end

    it "returns true when action items are included" do
      webhook = described_class.new({ "id" => "webhook_123", "include_action_items" => true })
      expect(webhook.include_action_items?).to be true
    end
  end

  describe "#include_crm_matches?" do
    it "returns false when CRM matches are not included" do
      expect(webhook.include_crm_matches?).to be false
    end

    it "returns true when CRM matches are included" do
      webhook = described_class.new({ "id" => "webhook_123", "include_crm_matches" => true })
      expect(webhook.include_crm_matches?).to be true
    end
  end

  describe "#active?" do
    it "returns true when active is true" do
      expect(webhook.active?).to be true
    end

    it "returns true when status is active" do
      webhook = described_class.new({ "id" => "webhook_123", "status" => "active" })
      expect(webhook.active?).to be true
    end

    it "returns false when active is false" do
      webhook = described_class.new({ "id" => "webhook_123", "active" => false })
      expect(webhook.active?).to be false
    end
  end

  describe "#secret" do
    it "returns the webhook secret" do
      expect(webhook.secret).to eq("whsec_12345")
    end
  end

  describe "#triggered_for" do
    it "returns the triggered_for configuration" do
      expect(webhook.triggered_for).to eq(%w[my_recordings shared_external_recordings])
    end

    it "returns nil when not set" do
      webhook = described_class.new({ "id" => "webhook_123" })
      expect(webhook.triggered_for).to be_nil
    end
  end
end
