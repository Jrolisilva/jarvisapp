# frozen_string_literal: true

require 'mongo'
require 'singleton'

# MongoConnection: Singleton wrapper for Mongo::Client
class MongoConnection
  include Singleton

  attr_reader :client

  def initialize
    retries = 5

    begin
      @client = Mongo::Client.new(mongo_url, mongo_options)

      @client.database_names
    rescue Mongo::Error, Errno::ECONNREFUSED => e
      puts "Mongo not ready yet: #{e.message}"
      retries -= 1
      if retries > 0
        sleep 2
        retry
      else
        puts "Mongo connection failed after retries. Exiting..."
        exit(1)
      end
    end
  end

  def collection(name)
    client[name.to_sym]
  end

  private

  def mongo_url
    ENV.fetch('MONGO_URL') {
      'mongodb://jarvisapp:jarvisapp@mongo:27017/jarvisapp?authSource=admin'
    }
  end

  def mongo_options
    {
      database: ENV.fetch('MONGO_DB', 'jarvisapp'),
      user: ENV['MONGO_INITDB_ROOT_USERNAME'],
      password: ENV['MONGO_INITDB_ROOT_PASSWORD'],
      server_selection_timeout: 2,
      connect_timeout: 2,
      socket_timeout: 2
    }
  end
end
