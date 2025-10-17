# frozen_string_literal: true

module Fathom
  class Recording < Resource
    def self.resource_path = "recordings"

    # Get summary for a recording
    # @param recording_id [Integer] The recording ID
    # @param destination_url [String, nil] Optional webhook URL for async delivery
    # @return [Hash] Summary data or destination confirmation
    def self.get_summary(recording_id, destination_url: nil)
      params = destination_url ? { destination_url: } : {}
      response = client.get("#{resource_path}/#{recording_id}/summary", params)

      response["summary"] || response
    end

    # Get transcript for a recording
    # @param recording_id [Integer] The recording ID
    # @param destination_url [String, nil] Optional webhook URL for async delivery
    # @return [Hash] Transcript data or destination confirmation
    def self.get_transcript(recording_id, destination_url: nil)
      params = destination_url ? { destination_url: } : {}
      response = client.get("#{resource_path}/#{recording_id}/transcript", params)

      response["transcript"] || response
    end

    # Recordings don't have a standard list endpoint
    def self.all(_params = {})
      raise NotImplementedError,
            "Recording.all is not supported. Recordings are accessed via Meeting#recording_id"
    end

    # Recordings don't have a standard retrieve endpoint
    # Use get_summary or get_transcript instead
    def self.retrieve(_id)
      raise NotImplementedError,
            "Recording.retrieve is not supported. Use Recording.get_summary(id) or Recording.get_transcript(id)"
    end
  end
end
