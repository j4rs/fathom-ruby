# frozen_string_literal: true

module Fathom
  class Team < Resource
    def self.resource_path = "teams"

    # Get all members of this team by filtering by team name
    # Note: Requires the team to have a 'name' attribute
    def members(params = {}) = TeamMember.all(params.merge(team: name))

    # Get the team name
    def name = self["name"]

    # Get the created_at timestamp
    def created_at = self["created_at"]
  end
end
