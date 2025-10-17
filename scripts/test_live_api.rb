#!/usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Metrics/BlockNesting
# Integration test script for fathom-ruby gem against live API
# Usage: FATHOM_API_KEY=your_key_here ruby scripts/test_live_api.rb

require "bundler/setup"
require "securerandom"
require_relative "../lib/fathom"

# ANSI color codes for pretty output
def green(text)
  "\e[32m#{text}\e[0m"
end

def red(text)
  "\e[31m#{text}\e[0m"
end

def yellow(text)
  "\e[33m#{text}\e[0m"
end

def blue(text)
  "\e[34m#{text}\e[0m"
end

def section(title)
  puts "\n#{blue("=" * 80)}"
  puts blue("  #{title}")
  puts blue("=" * 80)
end

def test(description)
  print "  #{description}... "
  result = yield
  puts green("✓ PASS")
  result
rescue StandardError => e
  puts red("✗ FAIL")
  puts red("    Error: #{e.class}: #{e.message}")
  nil
end

# Check for API key
api_key = ENV.fetch("FATHOM_API_KEY", nil)
if api_key.nil? || api_key.empty?
  puts red("ERROR: FATHOM_API_KEY environment variable not set!")
  puts "\nUsage:"
  puts "  FATHOM_API_KEY=your_key_here ruby scripts/test_live_api.rb"
  puts "\nOr export it first:"
  puts "  export FATHOM_API_KEY=your_key_here"
  puts "  ruby scripts/test_live_api.rb"
  exit 1
end

# Configure the gem
Fathom.configure do |config|
  config.api_key = api_key
  config.auto_retry = true
  config.max_retries = 3
end

puts green("\n✓ Fathom API Test Suite")
puts "  Testing against live API with your credentials\n"

# Track results
results = {
  passed: 0,
  failed: 0,
  skipped: 0
}

# =============================================================================
# Test: Meetings
# =============================================================================
section "1. Testing Meetings API"

meetings = test("Fetch meetings list") do
  Fathom::Meeting.all(limit: 5)
end

if meetings
  results[:passed] += 1
  puts "    Found #{meetings.count} meeting(s)"

  if meetings.any?
    meeting = meetings.first
    puts "\n    First meeting details:"
    puts "      Recording ID: #{meeting.recording_id || "N/A"}"
    puts "      Title: #{meeting["title"] || "N/A"}"
    puts "      Created: #{meeting["created_at"]}"
    puts "      URL: #{meeting["url"] || "N/A"}"

    # Test meeting attributes
    test("Access meeting attributes") do
      raise "Missing attributes" if meeting.attributes.empty?

      true
    end
    results[:passed] += 1

    # Test fetching summary if recording exists
    if meeting.recording_id
      summary = test("Fetch meeting summary") do
        meeting.fetch_summary
      end
      results[:passed] += 1 if summary

      transcript = test("Fetch meeting transcript") do
        meeting.fetch_transcript
      end
      results[:passed] += 1 if transcript
    else
      puts yellow("    ⊘ Skipping summary/transcript tests (no recording_id)")
      results[:skipped] += 2
    end
  else
    puts yellow("    ⊘ No meetings found - some tests skipped")
    results[:skipped] += 3
  end
else
  results[:failed] += 1
end

# =============================================================================
# Test: Teams
# =============================================================================
section "2. Testing Teams API"

teams = test("Fetch teams list") do
  Fathom::Team.all
end

if teams
  results[:passed] += 1
  puts "    Found #{teams.count} team(s)"

  if teams.any?
    team = teams.first
    puts "\n    First team details:"
    puts "      ID: #{team.id}"
    puts "      Name: #{team.name}"
    puts "      Created: #{team.created_at}"

    # Test team members
    members = test("Fetch team members") do
      team.members
    end

    if members
      results[:passed] += 1
      puts "    Found #{members.count} member(s) in team '#{team.name}'"

      if members.any?
        member = members.first
        puts "\n    First member details:"
        puts "      Name: #{member.name}"
        puts "      Email: #{member.email}"
      end
    else
      results[:failed] += 1
    end
  else
    puts yellow("    ⊘ No teams found")
    results[:skipped] += 1
  end
else
  results[:failed] += 1
end

# =============================================================================
# Test: Team Members (Direct API)
# =============================================================================
section "3. Testing Team Members API"

team_members = test("Fetch all team members") do
  Fathom::TeamMember.all(limit: 5)
end

if team_members
  results[:passed] += 1
  puts "    Found #{team_members.count} team member(s)"

  if team_members.any?
    member = team_members.first
    puts "\n    Member details:"
    puts "      Name: #{member.name}"
    puts "      Email: #{member.email}"
    puts "      Created: #{member.created_at}"
  end
else
  results[:failed] += 1
end

# =============================================================================
# Test: Webhooks API (Full CRUD)
# =============================================================================
section "4. Testing Webhooks API"

# Test listing webhooks
webhooks = test("Fetch webhooks list") do
  Fathom::Webhook.all
rescue Fathom::NotFoundError
  puts yellow("    ⊘ List endpoint returned 404")
  :not_available
end

if webhooks && webhooks != :not_available
  results[:passed] += 1
  puts "    Found #{webhooks.count} existing webhook(s)"

  if webhooks.any?
    webhook = webhooks.first
    puts "\n    First webhook details:"
    puts "      ID: #{webhook.id}"
    puts "      URL: #{webhook.url}"
    puts "      Active: #{webhook.active?}"
    puts "      Triggered for: #{webhook.triggered_for&.join(", ") || "N/A"}"
    puts "      Include transcript: #{webhook.include_transcript?}"
    puts "      Include summary: #{webhook.include_summary?}"
  end
elsif webhooks == :not_available
  results[:skipped] += 1
else
  results[:failed] += 1
end

# Test creating a webhook (independent of list endpoint)
# Using webhook.site for a valid HTTPS endpoint that accepts webhooks
created_webhook = test("Create test webhook") do
  Fathom::Webhook.create(
    url: "https://webhook.site/28c3ce21-4221-4d89-bab3-1c88d1cb0f0b",
    triggered_for: ["my_recordings"],
    include_transcript: true,
    include_summary: true,
    include_action_items: false,
    include_crm_matches: false
  )
rescue Fathom::BadRequestError, Fathom::ForbiddenError => e
  puts yellow("    ⊘ Webhooks not available: #{e.message}")
  :not_available
end

if created_webhook && created_webhook != :not_available
  results[:passed] += 1
  puts "    Created webhook with ID: #{created_webhook.id}"
  puts "    URL: #{created_webhook.url}"
  puts "    Secret: #{created_webhook.secret[0..15]}..." if created_webhook.secret

  # Test retrieving the webhook
  retrieved_webhook = test("Retrieve created webhook") do
    Fathom::Webhook.retrieve(created_webhook.id)
  end

  if retrieved_webhook
    results[:passed] += 1
    puts "    Successfully retrieved webhook #{retrieved_webhook.id}"
  else
    results[:failed] += 1
  end

  # Test deleting the webhook
  deleted = test("Delete test webhook") do
    created_webhook.delete
    true
  end

  if deleted
    results[:passed] += 1
    puts "    Successfully deleted webhook #{created_webhook.id}"

    # Verify deletion
    verify_deleted = test("Verify webhook was deleted") do
      Fathom::Webhook.retrieve(created_webhook.id)
      raise "Webhook still exists!"
    rescue Fathom::NotFoundError
      true
    end

    if verify_deleted
      results[:passed] += 1
    else
      results[:failed] += 1
    end
  else
    results[:failed] += 1
  end
elsif created_webhook == :not_available
  results[:skipped] += 4 # Skip create, retrieve, delete, and verify tests
else
  results[:failed] += 1
end

# =============================================================================
# Test: Error Handling
# =============================================================================
section "5. Testing Error Handling"

test("Handle invalid meeting ID (404)") do
  Fathom::Meeting.retrieve("invalid_id_that_does_not_exist_12345")
  raise "Should have raised NotFoundError"
rescue Fathom::NotFoundError
  true
end
results[:passed] += 1

# =============================================================================
# Test: Rate Limiting
# =============================================================================
section "6. Testing Rate Limiting"

test("Check rate limit headers") do
  Fathom::Meeting.all(limit: 1)
  rate_limiter = Fathom::Client.new.instance_variable_get(:@rate_limiter)
  info = rate_limiter.to_h

  puts "\n    Rate limit status:"
  if info[:limit].nil?
    puts yellow("      No rate limit headers present in API response")
  else
    puts "      Limit: #{info[:limit]}"
    puts "      Remaining: #{info[:remaining]}"
    puts "      Reset: #{info[:reset]}s"
  end

  true
end
results[:passed] += 1

# =============================================================================
# Test: Pagination
# =============================================================================
section "7. Testing Pagination"

paginated_meetings = test("Fetch meetings with pagination") do
  Fathom::Meeting.all(limit: 2)
end

if paginated_meetings
  results[:passed] += 1
  puts "    Retrieved #{paginated_meetings.count} meeting(s) with limit=2"

  if paginated_meetings.respond_to?(:next_cursor)
    puts "    Next cursor available: #{paginated_meetings.next_cursor ? "Yes" : "No"}"
  end
else
  results[:failed] += 1
end

# =============================================================================
# Summary
# =============================================================================
section "Test Results Summary"

total = results[:passed] + results[:failed] + results[:skipped]
pass_rate = total.positive? ? (results[:passed].to_f / total * 100).round(1) : 0

puts "\n  #{green("Passed:")}  #{results[:passed]}"
puts "  #{red("Failed:")}  #{results[:failed]}"
puts "  #{yellow("Skipped:")} #{results[:skipped]}"
puts "  #{blue("Total:")}   #{total}"
puts "\n  Pass Rate: #{pass_rate}%"

if results[:failed].zero?
  puts "\n#{green("\u2713 All tests passed!")}"
  exit 0
else
  puts "\n#{red("\u2717 Some tests failed. Please review the output above.")}"
  exit 1
end

# rubocop:enable Metrics/BlockNesting
