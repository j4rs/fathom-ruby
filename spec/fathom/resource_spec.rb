# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Resource do
  let(:attributes) { { "id" => "123", "name" => "Test Resource" } }
  let(:resource) { described_class.new(attributes) }

  describe "#initialize" do
    it "sets attributes" do
      expect(resource.attributes).to eq(attributes)
    end

    it "accepts rate_limit_info" do
      rate_limit_info = { limit: 60, remaining: 45 }
      resource = described_class.new(attributes, rate_limit_info: rate_limit_info)

      expect(resource.rate_limit_info).to eq(rate_limit_info)
    end
  end

  describe "#id" do
    it "returns the id attribute" do
      expect(resource.id).to eq("123")
    end
  end

  describe "#[]" do
    it "returns attribute by string key" do
      expect(resource["name"]).to eq("Test Resource")
    end

    it "returns attribute by symbol key" do
      expect(resource[:name]).to eq("Test Resource")
    end
  end

  describe "#[]=" do
    it "sets attribute by string key" do
      resource["status"] = "active"
      expect(resource["status"]).to eq("active")
    end

    it "sets attribute by symbol key" do
      resource[:status] = "active"
      expect(resource["status"]).to eq("active")
    end
  end

  describe "#to_h" do
    it "returns attributes hash" do
      expect(resource.to_h).to eq(attributes)
    end
  end

  describe "#to_json" do
    it "returns JSON representation" do
      expect(resource.to_json).to eq(attributes.to_json)
    end
  end

  describe "dynamic attribute access" do
    it "allows reading attributes via method calls" do
      expect(resource.name).to eq("Test Resource")
    end

    it "allows writing attributes via method calls" do
      resource.status = "active"
      expect(resource["status"]).to eq("active")
    end

    it "raises NoMethodError for non-existent attributes" do
      expect { resource.non_existent }.to raise_error(NoMethodError)
    end
  end

  describe ".all" do
    it "fetches all resources" do
      stub_fathom_request(:get, "resources", response_body: { items: [attributes] })

      resources = described_class.all
      expect(resources).to be_an(Array)
      expect(resources.first).to be_a(described_class)
      expect(resources.first.id).to eq("123")
    end

    it "passes parameters to the request" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/resources?limit=10")
             .with(headers: { "X-Api-Key" => "test_api_key" })
             .to_return(status: 200, body: { items: [] }.to_json)

      described_class.all(limit: 10)
      expect(stub).to have_been_requested
    end
  end

  describe ".retrieve" do
    it "fetches a single resource by ID" do
      stub_fathom_request(:get, "resources/123", response_body: { data: attributes })

      resource = described_class.retrieve("123")
      expect(resource).to be_a(described_class)
      expect(resource.id).to eq("123")
    end
  end

  describe ".create" do
    it "creates a new resource" do
      stub_fathom_request(:post, "resources", response_body: { data: attributes })

      resource = described_class.create(name: "Test Resource")
      expect(resource).to be_a(described_class)
      expect(resource.id).to eq("123")
    end
  end

  describe "#update" do
    it "updates the resource" do
      stub_fathom_request(:patch, "resources/123", response_body: { data: attributes.merge("name" => "Updated") })

      resource.update(name: "Updated")
      expect(resource.name).to eq("Updated")
    end
  end

  describe "#delete" do
    it "deletes the resource" do
      stub_fathom_request(:delete, "resources/123", status: 204)

      expect(resource.delete).to be true
    end
  end

  describe "#reload" do
    it "reloads the resource from the API" do
      updated_attributes = attributes.merge("name" => "Updated")
      stub_fathom_request(:get, "resources/123", response_body: { data: updated_attributes })

      resource.reload
      expect(resource.name).to eq("Updated")
    end
  end
end
