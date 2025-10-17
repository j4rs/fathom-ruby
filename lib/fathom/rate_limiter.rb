# frozen_string_literal: true

module Fathom
  class RateLimiter
    attr_reader :limit, :remaining, :reset

    def initialize
      @limit = nil
      @remaining = nil
      @reset = nil
    end

    def update_from_headers(headers)
      @limit = extract_header_value(headers, "RateLimit-Limit")&.to_i
      @remaining = extract_header_value(headers, "RateLimit-Remaining")&.to_i
      @reset = extract_header_value(headers, "RateLimit-Reset")&.to_i

      Fathom.log("Rate limit: #{@remaining}/#{@limit}, resets in #{@reset}s")
    end

    def should_retry? = Fathom.auto_retry && @remaining&.zero?

    def wait_time
      return 0 unless @reset

      # Add a small buffer
      @reset + 1
    end

    def rate_limited? = @remaining&.zero?

    def to_h = { limit: @limit, remaining: @remaining, reset: @reset }

    private

    def extract_header_value(headers, key)
      # Net::HTTP lowercases header keys, but direct hash access might not
      # Try original case first, then lowercase (for Net::HTTP)
      value = headers[key] || headers[key.downcase]
      # Handle both string and array formats (Net::HTTP returns arrays)
      value.is_a?(Array) ? value.first : value
    end
  end
end
