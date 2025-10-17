# frozen_string_literal: true

module Fathom
  class Meeting < Resource
    def self.resource_path = "meetings"

    # Get the recording ID for this meeting
    def recording_id = self["recording_id"]

    # Get the summary for this meeting (use include_summary=true when listing)
    # Returns the default_summary object or nil
    def summary = self["default_summary"]

    # Get the transcript for this meeting (use include_transcript=true when listing)
    # Returns array of transcript segments or nil
    def transcript = self["transcript"]

    # Fetch the recording summary from the API
    def fetch_summary(destination_url: nil)
      return nil unless recording_id

      Recording.get_summary(recording_id, destination_url:)
    end

    # Fetch the recording transcript from the API
    def fetch_transcript(destination_url: nil)
      return nil unless recording_id

      Recording.get_transcript(recording_id, destination_url:)
    end

    # Check if the meeting has a recording
    def recording? = !recording_id.nil?

    # Get meeting participants (calendar invitees)
    def participants = self["calendar_invitees"] || []

    # Get action items for the meeting
    def action_items = self["action_items"] || []
  end
end
