# Ruby API

A bare-bones API server implementation in Ruby.

## Purpose

This API is not intended for production use. It was built in pure Ruby to
demonstrate the basics of API design and HTTP server implementation, without all
the magic and ceremony of a full web framework.

## Architecture

- `server.rb` - Main entry point (sinatra-like API DSL)
- `lib/app.rb` - Application class with routing
- `lib/router.rb` - Simple HTTP router
- `lib/request.rb` - Request wrapper
- `lib/response.rb` - Response wrapper

## Dependencies

Prior to Ruby 3.0, this server does NOT require any external gems.

For Ruby 3.0 and later, the `webrick` gem is needed because it was removed from
the standard library 😢
