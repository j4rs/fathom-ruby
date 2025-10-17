# frozen_string_literal: true

module Fathom
  class Client
    BASE_URL = "https://api.fathom.ai/external/v1"

    attr_reader :rate_limiter

    def initialize
      @rate_limiter = RateLimiter.new
    end

    def get(path, params = {}) = request(:get, path, params:)

    def post(path, body = {}) = request(:post, path, body:)

    def put(path, body = {}) = request(:put, path, body:)

    def patch(path, body = {}) = request(:patch, path, body:)

    def delete(path) = request(:delete, path)

    private

    def request(method, path, params: {}, body: {}, retry_count: 0)
      uri = build_uri(path, params)
      http = build_http(uri)
      request_obj = build_request(method, uri, body)

      Fathom.log_http("#{method.upcase} #{uri}")
      Fathom.log_http("Headers: #{request_obj.to_hash}") if Fathom.debug_http
      Fathom.log_http("Body: #{body.to_json}") if Fathom.debug_http && body.present?

      response = http.request(request_obj)

      Fathom.log_http("Response: #{response.code} #{response.message}")
      @rate_limiter.update_from_headers(response.to_hash)

      handle_response(response, method, path, params, body, retry_count)
    end

    def build_uri(path, params)
      # Ensure path starts with /
      path = "/#{path}" unless path.start_with?("/")
      uri = URI.parse("#{BASE_URL}#{path}")
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri
    end

    def build_http(uri)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 60
      http.open_timeout = 30
      http
    end

    def build_request(method, uri, body)
      request_class =
        case method
        in :get then Net::HTTP::Get
        in :post then Net::HTTP::Post
        in :put then Net::HTTP::Put
        in :patch then Net::HTTP::Patch
        in :delete then Net::HTTP::Delete
        else raise ArgumentError, "Unsupported HTTP method: #{method}"
        end

      request = request_class.new(uri)
      request["X-Api-Key"] = Fathom.api_key
      request["Content-Type"] = "application/json"
      request["Accept"] = "application/json"
      request["User-Agent"] = "fathom-ruby/#{Fathom::VERSION}"

      request.body = body.to_json unless body.empty?

      request
    end

    def handle_response(response, method, path, params, body, retry_count)
      case response.code.to_i
      when 200, 201
        parse_json(response.body)
      when 204
        {} # No content
      when 400
        raise BadRequestError.new(parse_error_message(response), response: response, http_status: 400)
      when 401
        raise AuthenticationError.new(parse_error_message(response), response: response, http_status: 401)
      when 403
        raise ForbiddenError.new(parse_error_message(response), response: response, http_status: 403)
      when 404
        raise NotFoundError.new(parse_error_message(response), response: response, http_status: 404)
      when 429
        handle_rate_limit(response, method, path, params, body, retry_count)
      when 500..599
        raise ServerError.new(parse_error_message(response), response: response, http_status: response.code.to_i)
      else
        raise Error.new("Unexpected response: #{response.code}", response: response, http_status: response.code.to_i)
      end
    end

    def handle_rate_limit(response, method, path, params, body, retry_count)
      if Fathom.auto_retry && retry_count < Fathom.max_retries
        wait_time = calculate_backoff(retry_count)
        Fathom.log("Rate limited. Retrying in #{wait_time}s (attempt #{retry_count + 1}/#{Fathom.max_retries})")
        sleep(wait_time)
        request(method, path, params: params, body: body, retry_count: retry_count + 1)
      else
        raise RateLimitError.new(
          parse_error_message(response),
          response: response,
          http_status: 429,
          headers: response.to_hash
        )
      end
    end

    # Exponential backoff: 2^retry_count seconds, max 60 seconds
    def calculate_backoff(retry_count) = [2**retry_count, 60].min

    def parse_json(body)
      return {} if body.nil? || body.empty?

      JSON.parse(body)
    rescue JSON::ParserError => e
      Fathom.log("Failed to parse JSON: #{e.message}")
      {}
    end

    def parse_error_message(response)
      body = parse_json(response.body)
      body["error"] || body["message"] || "HTTP #{response.code}: #{response.message}"
    rescue StandardError
      "HTTP #{response.code}: #{response.message}"
    end
  end
end
