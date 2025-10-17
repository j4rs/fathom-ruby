# frozen_string_literal: true

require "net/http"
require "uri"
require "json"

require_relative "fathom/version"
require_relative "fathom/errors"
require_relative "fathom/client"
require_relative "fathom/rate_limiter"
require_relative "fathom/resource"
require_relative "fathom/resources/meeting"
require_relative "fathom/resources/recording"
require_relative "fathom/resources/team"
require_relative "fathom/resources/team_member"
require_relative "fathom/resources/webhook"

module Fathom
  class << self
    attr_writer :api_key, :auto_retry, :max_retries, :debug, :debug_http

    def configure
      yield self
    end

    def api_key
      @api_key || raise(Error, "Fathom.api_key is not configured")
    end

    def auto_retry = @auto_retry.nil? || @auto_retry

    def max_retries = @max_retries || 3

    def debug = @debug || false

    def debug_http = @debug_http || false

    def reset!
      @api_key = nil
      @auto_retry = true
      @max_retries = 3
      @debug = false
      @debug_http = false
    end

    def log(message)
      return unless debug

      puts "[Fathom] #{message}"
    end

    def log_http(message)
      return unless debug_http

      puts "[Fathom HTTP] #{message}"
    end
  end
end
