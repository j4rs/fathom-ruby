# frozen_string_literal: true

require "spec_helper"

RSpec.describe Fathom::Error do
  it "can be initialized with a message" do
    error = described_class.new("Test error")
    expect(error.message).to eq("Test error")
  end

  it "can store response and http_status" do
    error = described_class.new("Test error", response: "response_body", http_status: 400)
    expect(error.response).to eq("response_body")
    expect(error.http_status).to eq(400)
  end
end

RSpec.describe Fathom::AuthenticationError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end
end

RSpec.describe Fathom::NotFoundError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end
end

RSpec.describe Fathom::RateLimitError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end

  it "stores rate limit information from headers" do
    headers = {
      "RateLimit-Remaining" => "0",
      "RateLimit-Reset" => "60"
    }
    error = described_class.new("Rate limited", headers: headers)

    expect(error.rate_limit_remaining).to eq(0)
    expect(error.rate_limit_reset).to eq(60)
  end
end

RSpec.describe Fathom::ServerError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end
end

RSpec.describe Fathom::BadRequestError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end
end

RSpec.describe Fathom::ForbiddenError do
  it "inherits from Fathom::Error" do
    expect(described_class).to be < Fathom::Error
  end
end
