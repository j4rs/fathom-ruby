# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Team do
  let(:team_attributes) do
    {
      "id" => "team_123",
      "name" => "Engineering Team",
      "created_at" => "2025-01-15T10:30:00Z"
    }
  end
  let(:team) { described_class.new(team_attributes) }

  describe ".resource_path" do
    it "returns the correct API path" do
      expect(described_class.resource_path).to eq("teams")
    end
  end

  describe ".all" do
    it "fetches all teams" do
      stub_fathom_request(:get, "teams", response_body: { items: [team_attributes] })

      teams = described_class.all
      expect(teams).to be_an(Array)
      expect(teams.first).to be_a(described_class)
      expect(teams.first.name).to eq("Engineering Team")
    end
  end

  describe ".retrieve" do
    it "fetches a single team" do
      stub_fathom_request(:get, "teams/team_123", response_body: { data: team_attributes })

      team = described_class.retrieve("team_123")
      expect(team.id).to eq("team_123")
      expect(team.name).to eq("Engineering Team")
    end
  end

  describe "#name" do
    it "returns the team name" do
      expect(team.name).to eq("Engineering Team")
    end
  end

  describe "#created_at" do
    it "returns the created_at timestamp" do
      expect(team.created_at).to eq("2025-01-15T10:30:00Z")
    end
  end

  describe "#members" do
    it "fetches team members by team name" do
      member_data = { "name" => "John Doe", "email" => "john@example.com", "created_at" => "2024-06-01T08:30:00Z" }
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/team_members?team=Engineering%20Team")
             .to_return(status: 200, body: { items: [member_data] }.to_json,
                        headers: { "Content-Type" => "application/json" })

      members = team.members
      expect(members).to be_an(Array)
      expect(members.first).to be_a(Fathom::TeamMember)
      expect(stub).to have_been_requested
    end

    it "passes additional parameters to members request" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/team_members?cursor=abc123&team=Engineering%20Team")
             .to_return(status: 200, body: { items: [] }.to_json,
                        headers: { "Content-Type" => "application/json" })

      team.members(cursor: "abc123")
      expect(stub).to have_been_requested
    end
  end
end
