# Scripts

This directory contains utility scripts for development and testing.

## test_live_api.rb

Integration test script to verify the gem works correctly with the real Fathom API.

### Prerequisites

1. A Fathom account
2. An API key from your Fathom account (get it at: https://app.fathom.video/settings/integrations)

### Usage

**Option 1: Inline environment variable**

```bash
FATHOM_API_KEY=your_api_key_here ruby scripts/test_live_api.rb
```

**Option 2: Export environment variable**

```bash
export FATHOM_API_KEY=your_api_key_here
ruby scripts/test_live_api.rb
```

**Option 3: Use .env file (recommended for development)**

Create a `.env` file in the project root (already in .gitignore):

```bash
echo "export FATHOM_API_KEY=your_api_key_here" > .env
```

Then load it and run:

```bash
source .env
ruby scripts/test_live_api.rb
```

### What It Tests

The script performs the following tests against your live Fathom account:

1. **Meetings API**
   - Fetch meetings list
   - Access meeting attributes
   - Fetch meeting summaries (if recordings exist)
   - Fetch meeting transcripts (if recordings exist)

2. **Teams API**
   - Fetch teams list
   - Fetch team members for each team

3. **Team Members API**
   - Fetch all team members directly

4. **Webhooks API**
   - Fetch webhooks list
   - Create a test webhook
   - Retrieve the created webhook
   - Delete the test webhook
   - Verify deletion

5. **Error Handling**
   - Test 404 responses for invalid IDs

6. **Rate Limiting**
   - Verify rate limit headers are processed

7. **Pagination**
   - Test pagination with limit parameter

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

### Notes

- **Mostly read-only**: This script performs read operations for meetings, teams, and team members.
- **Webhook testing**: Creates a temporary test webhook and immediately deletes it to verify full CRUD operations.
- **Safe to run**: The test webhook is automatically cleaned up. You can run this script as many times as you want.
- **Rate limits**: The script respects Fathom's rate limits and will automatically retry if needed.

### Troubleshooting

**Error: FATHOM_API_KEY environment variable not set**
- Make sure you've set the environment variable before running the script

**401 Authentication Error**
- Your API key is invalid or has expired
- Get a new API key from https://app.fathom.video/settings/integrations

**404 Not Found (for meetings/teams)**
- Your account may not have any meetings or teams yet
- Try recording a meeting in Fathom first

**Rate Limit Exceeded**
- Wait a minute and try again
- The script will automatically retry with exponential backoff

