# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::RateLimiter do
  let(:rate_limiter) { described_class.new }

  describe "#update_from_headers" do
    it "extracts rate limit information from headers" do
      headers = {
        "RateLimit-Limit" => "60",
        "RateLimit-Remaining" => "45",
        "RateLimit-Reset" => "30"
      }

      rate_limiter.update_from_headers(headers)

      expect(rate_limiter.limit).to eq(60)
      expect(rate_limiter.remaining).to eq(45)
      expect(rate_limiter.reset).to eq(30)
    end

    it "handles missing headers gracefully" do
      rate_limiter.update_from_headers({})

      expect(rate_limiter.limit).to be_nil
      expect(rate_limiter.remaining).to be_nil
      expect(rate_limiter.reset).to be_nil
    end
  end

  describe "#should_retry?" do
    it "returns true when auto_retry is enabled and remaining is zero" do
      Fathom.auto_retry = true
      rate_limiter.update_from_headers({ "RateLimit-Remaining" => "0" })

      expect(rate_limiter.should_retry?).to be true
    end

    it "returns false when auto_retry is disabled" do
      Fathom.auto_retry = false
      rate_limiter.update_from_headers({ "RateLimit-Remaining" => "0" })

      expect(rate_limiter.should_retry?).to be false
    end

    it "returns false when remaining is not zero" do
      Fathom.auto_retry = true
      rate_limiter.update_from_headers({ "RateLimit-Remaining" => "10" })

      expect(rate_limiter.should_retry?).to be false
    end
  end

  describe "#wait_time" do
    it "returns reset time plus buffer" do
      rate_limiter.update_from_headers({ "RateLimit-Reset" => "5" })
      expect(rate_limiter.wait_time).to eq(6)
    end

    it "returns 0 when reset is not set" do
      expect(rate_limiter.wait_time).to eq(0)
    end
  end

  describe "#rate_limited?" do
    it "returns true when remaining is zero" do
      rate_limiter.update_from_headers({ "RateLimit-Remaining" => "0" })
      expect(rate_limiter.rate_limited?).to be true
    end

    it "returns false when remaining is not zero" do
      rate_limiter.update_from_headers({ "RateLimit-Remaining" => "10" })
      expect(rate_limiter.rate_limited?).to be false
    end
  end

  describe "#to_h" do
    it "returns rate limit info as hash" do
      headers = {
        "RateLimit-Limit" => "60",
        "RateLimit-Remaining" => "45",
        "RateLimit-Reset" => "30"
      }
      rate_limiter.update_from_headers(headers)

      expect(rate_limiter.to_h).to eq(
        limit: 60,
        remaining: 45,
        reset: 30
      )
    end
  end
end
