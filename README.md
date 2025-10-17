# Fathom API Ruby library

[Fathom](https://fathom.ai) is an AI meeting assistant that records, transcribes, highlights, and summarizes your meetings so you can focus on the conversation.

This is a comprehensive Ruby gem for interacting with the [Fathom API](https://developers.fathom.ai). This gem provides easy access to Fathom's REST API for managing meetings, recordings, teams, webhooks, and more.

[![CI](https://github.com/j4rs/fathom-ruby/workflows/CI/badge.svg)](https://github.com/j4rs/fathom-ruby/actions)
[![Gem Version](https://badge.fury.io/rb/fathom-ruby.svg)](https://badge.fury.io/rb/fathom-ruby)

## Features

- 🔄 Automatic rate limiting with configurable retries
- 🛡️ Comprehensive error handling
- 📝 Full support for all the existing Fathom API resources
- 🎯 Simple and intuitive API
- ✅ Verified against [official Fathom API documentation](https://developers.fathom.ai/api-reference)

## Requirements

- Ruby >= 3.1.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fathom-ruby'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install fathom-ruby
```

## Configuration

### Basic Setup

Configure the gem with your Fathom API key:

```ruby
require 'fathom'

Fathom.api_key = "your_api_key_here"
```

### Configuration Options

```ruby
Fathom.configure do |config|
  config.api_key = "your_api_key_here"

  # Enable/disable automatic retries on rate limits (default: true)
  config.auto_retry = true

  # Maximum number of retry attempts (default: 3)
  config.max_retries = 3

  # Enable debug logging (default: false)
  config.debug = Rails.env.development?

  # Enable HTTP request/response logging (default: false)
  config.debug_http = Rails.env.development?
end
```

### Rails Configuration

Create an initializer at `config/initializers/fathom.rb`:

```ruby
require 'fathom'

Fathom.configure do |config|
  config.api_key = ENV['FATHOM_API_KEY']
  # ... rest of the settings (like above)
end
```

## Usage

> **📋 Important Notes:**
> - The Fathom API uses **cursor-based pagination**, not offset-based
> - Response format is `{ items: [...] }`, not `{ data: [...] }`
> - **Team Members**: No individual IDs - filter by team name instead
> - **Recordings**: No list/retrieve endpoints - use specialized endpoints for summary/transcript

### Meetings

List all meetings:

```ruby
# Get all meetings
meetings = Fathom::Meeting.all

# With query parameters
meetings = Fathom::Meeting.all(
  cursor: "eyJwYWdlX251bSI6Mn0=",    # Cursor-based pagination
  include_summary: true,             # Include default_summary
  include_transcript: true,          # Include transcript
  include_action_items: true,        # Include action_items
  teams: ["Sales", "Engineering"]    # Filter by team names
)

# Filter by date range
meetings = Fathom::Meeting.all(
  created_after: "2025-01-01T00:00:00Z",
  created_before: "2025-01-31T23:59:59Z"
)

# Filter by calendar invitees
meetings = Fathom::Meeting.all(
  "calendar_invitees[]" => "ceo@acme.com"
)
```

Access meeting data:

```ruby
meeting = meetings.first

# Basic fields
puts meeting.title
puts meeting.recording_id

# Embedded data (when requested with include_* params)
puts meeting.summary                # Returns default_summary hash
puts meeting.summary["markdown_formatted"]
puts meeting.transcript             # Returns transcript array
puts meeting.participants           # Returns calendar_invitees array
puts meeting.action_items           # Returns action_items array
```

Fetch recording data for a meeting:

```ruby
meeting = meetings.first

# Fetch summary from Recording API
if meeting.recording?
  summary = meeting.fetch_summary
  puts summary["template_name"]
  puts summary["markdown_formatted"]

  # Fetch transcript from Recording API
  transcript = meeting.fetch_transcript
  transcript.each do |segment|
    puts "#{segment['speaker']['display_name']}: #{segment['text']}"
  end
end
```

### Recordings

**Note**: Recordings don't have standard list/retrieve endpoints. They're accessed via their specialized endpoints:

Get summary for a recording:

```ruby
# Synchronous - returns summary immediately
summary = Fathom::Recording.get_summary(123456789)

puts summary["template_name"]      # e.g., "general"
puts summary["markdown_formatted"]  # Formatted summary text
```

Get transcript for a recording:

```ruby
# Synchronous - returns transcript immediately
transcript = Fathom::Recording.get_transcript(123456789)

transcript.each do |segment|
  speaker = segment["speaker"]["display_name"]
  text = segment["text"]
  timestamp = segment["timestamp"]

  puts "[#{timestamp}] #{speaker}: #{text}"
end
```

Async mode with webhooks:

```ruby
# Async - sends result to your webhook URL
Fathom::Recording.get_summary(
  123456789,
  destination_url: "https://your-app.com/webhooks/summary"
)

Fathom::Recording.get_transcript(
  123456789,
  destination_url: "https://your-app.com/webhooks/transcript"
)
```

### Teams

List all teams:

```ruby
teams = Fathom::Team.all

teams.each do |team|
  puts team.name
  puts "Created: #{team.created_at}"
end
```

Get a specific team:

```ruby
team = Fathom::Team.retrieve("team_id")
puts team.name
```

List team members:

```ruby
team = Fathom::Team.retrieve("team_id")
members = team.members  # Automatically filters by team name

# Or directly by team name
members = Fathom::TeamMember.all(team: "Engineering")
```

### Team Members

List all team members:

```ruby
# List all team members
members = Fathom::TeamMember.all

members.each do |member|
  puts "#{member.name} (#{member.email})"
  puts "Created: #{member.created_at}"
end
```

Filter by team name:

```ruby
# Filter by specific team name
members = Fathom::TeamMember.all(team: "Engineering")

members.each do |member|
  puts "#{member.name} - #{member.email}"
end
```

Pagination with cursor:

```ruby
# First page
response = Fathom::TeamMember.all(team: "Sales")

# Next page (if cursor is available from API response)
next_page = Fathom::TeamMember.all(team: "Sales", cursor: "next_cursor_value")
```

**Note:** Team members don't have individual IDs in the Fathom API. Use filtering instead of retrieving individual members.

### Webhooks

List all webhooks:

```ruby
webhooks = Fathom::Webhook.all

webhooks.each do |webhook|
  puts "#{webhook.url}"
  puts "  Includes transcript: #{webhook.include_transcript?}"
  puts "  Includes summary: #{webhook.include_summary?}"
  puts "  Active: #{webhook.active?}"
end
```

Create a webhook:

```ruby
webhook = Fathom::Webhook.create(
  url: "https://example.com/webhook",
  # Specify which recordings should trigger the webhook:
  # - my_recordings: Your own recordings
  # - shared_external_recordings: Recordings shared with you externally
  # - my_shared_with_team_recordings: Your recordings shared with your team
  # - shared_team_recordings: Team recordings shared with you
  triggered_for: ["my_recordings", "shared_external_recordings"],
  include_transcript: true,
  include_summary: true,
  include_action_items: true,
  include_crm_matches: false
)

puts webhook.id
puts webhook.secret
puts webhook.triggered_for  # => ["my_recordings", "shared_external_recordings"]
```

Get a specific webhook:

```ruby
webhook = Fathom::Webhook.retrieve("webhook_id")

if webhook.active?
  puts "Webhook is active"
end
```

Delete a webhook:

```ruby
webhook = Fathom::Webhook.retrieve("webhook_id")
webhook.delete
```

Check webhook configuration:

```ruby
webhook = Fathom::Webhook.retrieve("webhook_id")

puts "Active: #{webhook.active?}"
puts "Triggered for: #{webhook.triggered_for.join(', ')}"
puts "Includes transcript: #{webhook.include_transcript?}"
puts "Includes summary: #{webhook.include_summary?}"
puts "Includes action items: #{webhook.include_action_items?}"
puts "Includes CRM matches: #{webhook.include_crm_matches?}"
```

## Rate Limiting

The Fathom API has a rate limit of 60 requests per 60 seconds. This gem handles rate limiting automatically.

### Automatic Retries (Default)

By default, the gem will automatically retry requests when rate limited:

```ruby
Fathom.auto_retry = true  # This is the default
Fathom.max_retries = 3    # Maximum retry attempts

# Requests will automatically retry with exponential backoff
meetings = Fathom::Meeting.all
```

### Manual Rate Limit Handling

Disable automatic retries and handle rate limits manually:

```ruby
Fathom.auto_retry = false

begin
  meetings = Fathom::Meeting.all
rescue Fathom::RateLimitError => e
  # Handle rate limit error
  puts "Rate limited. Remaining: #{e.rate_limit_remaining}"
  puts "Reset in: #{e.rate_limit_reset} seconds"

  # Wait and retry manually
  sleep(e.rate_limit_reset)
  retry
end
```

### Checking Rate Limit Info

Access rate limit information from any resource:

```ruby
meetings = Fathom::Meeting.all
rate_info = meetings.first.rate_limit_info

puts "Limit: #{rate_info[:limit]}"
puts "Remaining: #{rate_info[:remaining]}"
puts "Reset in: #{rate_info[:reset]} seconds"
```

## Error Handling

The gem provides specific error classes for different scenarios:

```ruby
begin
  meeting = Fathom::Meeting.retrieve("invalid_id")
rescue Fathom::AuthenticationError => e
  # 401 - Invalid API key
  puts "Authentication failed: #{e.message}"
rescue Fathom::NotFoundError => e
  # 404 - Resource not found
  puts "Meeting not found: #{e.message}"
rescue Fathom::RateLimitError => e
  # 429 - Rate limit exceeded
  puts "Rate limited: #{e.message}"
rescue Fathom::BadRequestError => e
  # 400 - Bad request
  puts "Bad request: #{e.message}"
rescue Fathom::ForbiddenError => e
  # 403 - Forbidden
  puts "Access forbidden: #{e.message}"
rescue Fathom::ServerError => e
  # 5xx - Server error
  puts "Server error: #{e.message}"
rescue Fathom::Error => e
  # Any other Fathom error
  puts "Error: #{e.message}"
end
```

All error objects include:

- `message` - Human-readable error message
- `http_status` - HTTP status code
- `response` - Raw response object

## Dynamic Attribute Access

All resources support dynamic attribute access:

```ruby
meeting = Fathom::Meeting.retrieve("meeting_id")

# Access attributes
meeting.title
meeting.summary
meeting["custom_field"]

# Set attributes
meeting.title = "New Title"
meeting["custom_field"] = "value"

# Convert to hash
meeting.to_h

# Convert to JSON
meeting.to_json
```

## Debugging

Enable debug logging to see what's happening:

```ruby
# Basic debug logging
Fathom.debug = true

# HTTP request/response logging
Fathom.debug_http = true

# Now all API calls will be logged
meetings = Fathom::Meeting.all
# [Fathom] Rate limit: 59/60, resets in 60s
# [Fathom HTTP] GET https://api.fathom.ai/v1/meetings
# [Fathom HTTP] Response: 200 OK
```

### Testing live
Check [Test Live API Readme](./scripts/README.md) for instructions to test the API using a real API Key.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

### Running Tests

```bash
bundle exec rspec
```

### Running Rubocop

```bash
bundle exec rubocop
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/j4rs/fathom-ruby. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](CODE_OF_CONDUCT.md).

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](LICENSE).

## Code of Conduct

Everyone interacting in the Fathom Ruby project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).

## Links

- [Fathom API Documentation](https://developers.fathom.ai)
- [Gem Documentation](https://rubydoc.info/gems/fathom-ruby)
- [GitHub Repository](https://github.com/j4rs/fathom-ruby)
- [Bug Reports](https://github.com/j4rs/fathom-ruby/issues)

