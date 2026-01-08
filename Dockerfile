# Dockerfile for the sample_project
FROM ruby:3.2.2-slim

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
        build-essential \
        curl \
        git \
        nodejs \
        npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /project

# Copy entire project
COPY . .

# Install all dependencies using the project's setup script
RUN bin/setup

# Default command starts all APIs
CMD ["bin/dev"]
