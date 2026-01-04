# Sample Project

A multi-language API project demonstrating the same HTTP server implemented in
different languages.

## Setup

```bash
bin/setup
```

*Prerequisites:*
- MacOS (or other POSIX-compliant OS)
- Ruby (any version)

## Start API Server

```bash
bin/dev
```

Press Ctrl+C to stop the server.

## Run Tests

```bash
bin/test
```

## Project Structure

- `ruby_api/` - Ruby implementation of the API
- `tests/` - Test suite for the API implementation
- `bin/` - Development and testing scripts

### Multiple Implementations

This project was structured to support multiple implementations of the API --
each contained within its own `*_api` folder -- to explore how the same
functionality can be achieved in different programming languages and frameworks.
