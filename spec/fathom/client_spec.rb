# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Client do
  let(:client) { described_class.new }

  describe "#get" do
    it "makes a GET request and returns parsed JSON" do
      stub_fathom_request(:get, "meetings", response_body: { items: [{ id: "1" }] })

      result = client.get("meetings")
      expect(result).to eq({ "items" => [{ "id" => "1" }] })
    end

    it "includes query parameters" do
      stub = stub_request(:get, "https://api.fathom.ai/external/v1/meetings?limit=10")
             .with(headers: { "X-Api-Key" => "test_api_key" })
             .to_return(status: 200, body: { items: [] }.to_json)

      client.get("meetings", limit: 10)
      expect(stub).to have_been_requested
    end
  end

  describe "#post" do
    it "makes a POST request with body" do
      stub = stub_request(:post, "https://api.fathom.ai/external/v1/webhooks")
             .with(
               body: { url: "https://example.com" }.to_json,
               headers: { "X-Api-Key" => "test_api_key" }
             )
             .to_return(status: 201, body: { data: { id: "1" } }.to_json)

      result = client.post("webhooks", url: "https://example.com")
      expect(result).to eq({ "data" => { "id" => "1" } })
      expect(stub).to have_been_requested
    end
  end

  describe "#delete" do
    it "makes a DELETE request" do
      stub_fathom_request(:delete, "webhooks/1", status: 204, response_body: {})

      result = client.delete("webhooks/1")
      expect(result).to eq({})
    end
  end

  describe "error handling" do
    it "raises AuthenticationError on 401" do
      stub_fathom_request(:get, "meetings", status: 401, response_body: { error: "Unauthorized" })

      expect { client.get("meetings") }.to raise_error(Fathom::AuthenticationError, /Unauthorized/)
    end

    it "raises NotFoundError on 404" do
      stub_fathom_request(:get, "meetings/999", status: 404, response_body: { error: "Not found" })

      expect { client.get("meetings/999") }.to raise_error(Fathom::NotFoundError, /Not found/)
    end

    it "raises BadRequestError on 400" do
      stub_fathom_request(:post, "webhooks", status: 400, response_body: { error: "Bad request" })

      expect { client.post("webhooks") }.to raise_error(Fathom::BadRequestError, /Bad request/)
    end

    it "raises ServerError on 500" do
      stub_fathom_request(:get, "meetings", status: 500, response_body: { error: "Server error" })

      expect { client.get("meetings") }.to raise_error(Fathom::ServerError, /Server error/)
    end
  end

  describe "rate limiting" do
    it "updates rate limiter from response headers" do
      stub_fathom_request(
        :get,
        "meetings",
        headers: {
          "RateLimit-Limit" => "60",
          "RateLimit-Remaining" => "45",
          "RateLimit-Reset" => "30"
        }
      )

      client.get("meetings")

      expect(client.rate_limiter.limit).to eq(60)
      expect(client.rate_limiter.remaining).to eq(45)
      expect(client.rate_limiter.reset).to eq(30)
    end

    context "when auto_retry is enabled" do
      before { Fathom.auto_retry = true }

      it "retries on 429 with exponential backoff" do
        # Mock sleep to avoid actual waiting
        allow(client).to receive(:sleep).and_return(nil)

        # First request fails with 429
        stub_rate_limited_request(:get, "meetings").times(1).then
                                                   .to_return(
                                                     status: 200,
                                                     body: { items: [] }.to_json,
                                                     headers: {
                                                       "Content-Type" => "application/json",
                                                       "RateLimit-Limit" => "60",
                                                       "RateLimit-Remaining" => "59",
                                                       "RateLimit-Reset" => "60"
                                                     }
                                                   )

        result = client.get("meetings")
        expect(result).to eq({ "items" => [] })
        expect(client).to have_received(:sleep).with(1)
      end

      it "raises RateLimitError after max retries" do
        Fathom.max_retries = 2
        stub_rate_limited_request(:get, "meetings")

        allow(client).to receive(:sleep).and_return(nil)

        expect { client.get("meetings") }.to raise_error(Fathom::RateLimitError)
        expect(client).to have_received(:sleep).twice
      end
    end

    context "when auto_retry is disabled" do
      before { Fathom.auto_retry = false }

      it "raises RateLimitError immediately on 429" do
        stub_rate_limited_request(:get, "meetings")

        expect { client.get("meetings") }.to raise_error(Fathom::RateLimitError)
      end
    end
  end

  describe "authentication" do
    it "includes API key in X-Api-Key header" do
      Fathom.api_key = "my_secret_key"

      stub = stub_request(:get, "https://api.fathom.ai/external/v1/meetings")
             .with(headers: { "X-Api-Key" => "my_secret_key" })
             .to_return(status: 200, body: { items: [] }.to_json)

      client.get("meetings")
      expect(stub).to have_been_requested
    end
  end
end
