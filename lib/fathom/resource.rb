# frozen_string_literal: true

module Fathom
  class Resource
    attr_reader :attributes, :rate_limit_info

    def initialize(attributes = {}, rate_limit_info: nil)
      @attributes = attributes
      @rate_limit_info = rate_limit_info
    end

    def id = @attributes["id"]

    def [](key) = @attributes[key.to_s]

    def []=(key, value)
      @attributes[key.to_s] = value
    end

    def to_h = @attributes

    def to_json(...) = @attributes.to_json(...)

    def inspect
      "#<#{self.class.name}:0x#{object_id.to_s(16)} id=#{id.inspect} #{@attributes.keys.join(", ")}>"
    end

    # Dynamic attribute access
    def method_missing(method_name, *args, &)
      method_str = method_name.to_s
      if method_str.end_with?("=")
        @attributes[method_str.chop] = args.first
      elsif @attributes.key?(method_str)
        @attributes[method_str]
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      method_str = method_name.to_s
      method_str.end_with?("=") || @attributes.key?(method_str) || super
    end

    class << self
      def client = @client ||= Client.new

      def resource_name = name.split("::").last.downcase

      def resource_path = "#{resource_name}s"

      def all(params = {})
        response = client.get(resource_path, params)
        # Fathom API returns items array
        data = response["items"] || response["data"] || []

        data.map { |attrs| new(attrs, rate_limit_info: client.rate_limiter.to_h) }
      end

      def retrieve(id)
        response = client.get("#{resource_path}/#{id}")
        data = response["data"] || response[resource_name] || response

        new(data, rate_limit_info: client.rate_limiter.to_h)
      end

      def create(attributes = {})
        response = client.post(resource_path, attributes)
        data = response["data"] || response[resource_name] || response

        new(data, rate_limit_info: client.rate_limiter.to_h)
      end

      def search(query, params = {})
        search_params = params.merge(q: query)
        response = client.get("#{resource_path}/search", search_params)
        data = response["data"] || response[resource_path] || []

        data.map { |attrs| new(attrs, rate_limit_info: client.rate_limiter.to_h) }
      end
    end

    def update(attributes = {})
      response = self.class.client.patch("#{self.class.resource_path}/#{id}", attributes)
      data = response["data"] || response[self.class.resource_name] || response

      @attributes.merge!(data)
      @rate_limit_info = self.class.client.rate_limiter.to_h

      self
    end

    def delete
      self.class.client.delete("#{self.class.resource_path}/#{id}")
      @rate_limit_info = self.class.client.rate_limiter.to_h

      true
    end

    def reload
      response = self.class.client.get("#{self.class.resource_path}/#{id}")
      data = response["data"] || response[self.class.resource_name] || response

      @attributes = data
      @rate_limit_info = self.class.client.rate_limiter.to_h

      self
    end
  end
end
