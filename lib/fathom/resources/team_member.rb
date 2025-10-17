# frozen_string_literal: true

module Fathom
  class TeamMember < Resource
    def self.resource_path = "team_members"

    # List all team members, optionally filtered by team name
    # @param params [Hash] Query parameters
    # @option params [String] :team Team name to filter by
    # @option params [String] :cursor Cursor for pagination
    # @return [Array<TeamMember>]
    def self.all(params = {})
      response = client.get(resource_path, params)
      data = response["items"] || []

      data.map { |attrs| new(attrs, rate_limit_info: client.rate_limiter.to_h) }
    end

    # Team members don't have individual retrieve endpoint in the API
    # Use .all with filters instead
    def self.retrieve(_id)
      raise NotImplementedError,
            "TeamMember.retrieve is not supported by the Fathom API. Use TeamMember.all instead."
    end

    # Get the member's email
    def email = self["email"]

    # Get the member's name
    def name = self["name"]

    # Get the created_at timestamp
    def created_at = self["created_at"]

    # Team members don't have an ID field in the API
    def id = nil
  end
end
