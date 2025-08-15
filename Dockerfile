FROM ruby:3.1.0 AS base

# Install dependencies
WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential libpq-dev \
    rm -rf /var/lib/apt/lists/*

# Install gems and dependencies
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Expose the application port
EXPOSE 3000

# Start the application
CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000", "-C", "config/puma.rb"]