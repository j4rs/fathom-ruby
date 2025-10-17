# frozen_string_literal: true

module Fathom
  class Webhook < Resource
    def self.resource_path = "webhooks"

    # Get the webhook URL
    def url = self["url"]

    # Check if webhook is active
    def active? = self["active"] == true || self["status"] == "active"

    # Get the webhook secret (if available)
    def secret = self["secret"]

    # Get triggered_for configuration
    # Possible values: "my_recordings", "shared_external_recordings",
    #                  "my_shared_with_team_recordings", "shared_team_recordings"
    def triggered_for = self["triggered_for"]

    # Check if transcript is included in webhook payload
    def include_transcript? = self["include_transcript"] == true

    # Check if summary is included in webhook payload
    def include_summary? = self["include_summary"] == true

    # Check if action items are included in webhook payload
    def include_action_items? = self["include_action_items"] == true

    # Check if CRM matches are included in webhook payload
    def include_crm_matches? = self["include_crm_matches"] == true
  end
end
