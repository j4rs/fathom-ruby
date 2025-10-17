# Testing the Gem

## Running Unit Tests

Run the full test suite:

```bash
bundle exec rspec
```

Run specific test files:

```bash
bundle exec rspec spec/fathom/client_spec.rb
bundle exec rspec spec/fathom/resources/meeting_spec.rb
```

Run with coverage:

```bash
bundle exec rspec
open coverage/index.html
```

## Testing Against Live API

We've created an integration test script that you can run against your real Fathom account.

### Quick Start

1. Get your API key from [Fathom Settings](https://app.fathom.video/settings/integrations)

2. Run the test script:

```bash
FATHOM_API_KEY=your_key_here ruby scripts/test_live_api.rb
```

### Using .env File (Recommended)

For convenience, create a `.env` file (already in `.gitignore`):

```bash
# Create .env file with your API key
echo "FATHOM_API_KEY=your_actual_api_key_here" > .env

# Load and run
source .env
ruby scripts/test_live_api.rb
```

### What Gets Tested

The live API test script verifies:

- ✅ **Meetings API**: List, attributes, summaries, transcripts
- ✅ **Teams API**: List teams and members
- ✅ **Team Members API**: List all members
- ✅ **Webhooks API**: Full CRUD (list, create, retrieve, delete)
- ✅ **Error Handling**: 404 responses
- ✅ **Rate Limiting**: Header processing
- ✅ **Pagination**: Limit parameters

### Sample Output

```
✓ Fathom API Test Suite
  Testing against live API with your credentials

================================================================================
  1. Testing Meetings API
================================================================================
  Fetch meetings list... ✓ PASS
    Found 5 meeting(s)

    First meeting details:
      ID: 123456
      Title: Weekly Team Sync
      Created: 2025-01-15T10:00:00Z
      Recording ID: 789012

  Access meeting attributes... ✓ PASS
  Fetch meeting summary... ✓ PASS
  Fetch meeting transcript... ✓ PASS

...

================================================================================
  Test Results Summary
================================================================================

  Passed:  15
  Failed:  0
  Skipped: 0
  Total:   15

  Pass Rate: 100.0%

✓ All tests passed!
```

### Important Notes

- **Mostly Read-Only**: Performs GET requests for meetings, teams, and team members
- **Webhook Testing**: Creates a temporary test webhook and immediately deletes it
- **Safe**: Test webhook is automatically cleaned up - run as many times as you want
- **Rate Limits**: Automatically handled with retries

See `scripts/README.md` for more details.

## Code Quality

Check code style:

```bash
bundle exec rubocop
```

Auto-fix issues:

```bash
bundle exec rubocop -A
```
