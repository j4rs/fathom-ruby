# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2025-10-17

### Added
- Full support for Fathom API v1
- **Meetings API**: List, retrieve, fetch summaries and transcripts
- **Recordings API**: Get summaries and transcripts with async delivery support
- **Teams API**: List teams and manage team members
- **Team Members API**: List and filter team members
- **Webhooks API**: Full CRUD operations (create, list, retrieve, delete)
- Automatic rate limiting with exponential backoff and configurable retries
- Comprehensive error handling with custom error classes
- Built with Ruby's native `Net::HTTP` (no external HTTP dependencies)
- Ruby 3.1+ support with modern syntax (endless methods, shorthand hash, pattern matching)
- Extensive test coverage (125 examples, 94.87% coverage)
- Live API integration test script
- Full RuboCop compliance

### Technical Details
- Authentication via `X-Api-Key` header
- Dynamic attribute access with `method_missing`
- Rate limit tracking and automatic retry logic
- Pagination support with cursor-based navigation
- Proper handling of API response formats

