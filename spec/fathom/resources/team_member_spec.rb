# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::TeamMember do
  let(:member_attributes) do
    {
      "name" => "Bob Lee",
      "email" => "bob.lee@acme.com",
      "created_at" => "2024-06-01T08:30:00Z"
    }
  end
  let(:member) { described_class.new(member_attributes) }

  describe ".resource_path" do
    it "returns the correct API path" do
      expect(described_class.resource_path).to eq("team_members")
    end
  end

  describe ".all" do
    it "fetches all team members" do
      stub_fathom_request(:get, "team_members", response_body: { items: [member_attributes] })

      members = described_class.all
      expect(members).to be_an(Array)
      expect(members.first).to be_a(described_class)
      expect(members.first.email).to eq("bob.lee@acme.com")
      expect(members.first.name).to eq("Bob Lee")
    end

    it "filters by team name" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/team_members?team=Engineering")
             .to_return(status: 200, body: { items: [member_attributes] }.to_json,
                        headers: { "Content-Type" => "application/json" })

      members = described_class.all(team: "Engineering")
      expect(members).to be_an(Array)
      expect(stub).to have_been_requested
    end

    it "supports pagination with cursor" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/team_members?cursor=abc123")
             .to_return(status: 200, body: { items: [] }.to_json,
                        headers: { "Content-Type" => "application/json" })

      described_class.all(cursor: "abc123")
      expect(stub).to have_been_requested
    end
  end

  describe ".retrieve" do
    it "raises NotImplementedError" do
      expect { described_class.retrieve("member_123") }.to raise_error(NotImplementedError, /not supported/)
    end
  end

  describe "#email" do
    it "returns the member email" do
      expect(member.email).to eq("bob.lee@acme.com")
    end
  end

  describe "#name" do
    it "returns the member name" do
      expect(member.name).to eq("Bob Lee")
    end
  end

  describe "#created_at" do
    it "returns the created_at timestamp" do
      expect(member.created_at).to eq("2024-06-01T08:30:00Z")
    end
  end

  describe "#id" do
    it "returns nil since team members don't have IDs in the API" do
      expect(member.id).to be_nil
    end
  end
end
