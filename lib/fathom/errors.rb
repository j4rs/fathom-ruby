# frozen_string_literal: true

module Fathom
  # Base error class for all Fathom errors
  class Error < StandardError
    attr_reader :response, :http_status

    def initialize(message = nil, response: nil, http_status: nil)
      @response = response
      @http_status = http_status
      super(message)
    end
  end

  # Raised when API authentication fails (401)
  class AuthenticationError < Error; end

  # Raised when a resource is not found (404)
  class NotFoundError < Error; end

  # Raised when rate limit is exceeded (429)
  class RateLimitError < Error
    attr_reader :rate_limit_remaining, :rate_limit_reset

    def initialize(message = nil, response: nil, http_status: nil, headers: {})
      @rate_limit_remaining = headers["RateLimit-Remaining"]&.to_i
      @rate_limit_reset = headers["RateLimit-Reset"]&.to_i
      super(message, response: response, http_status: http_status)
    end
  end

  # Raised when the server returns a 5xx error
  class ServerError < Error; end

  # Raised when the API returns a bad request (400)
  class BadRequestError < Error; end

  # Raised when the API returns a forbidden error (403)
  class ForbiddenError < Error; end
end
