# frozen_string_literal: true

require 'mongo'
require 'singleton'

# MongoConnection: Singleton wrapper for Mongo::Client
class MongoConnection
  include Singleton

  attr_reader :client

  def initialize
    @client = Mongo::Client.new(mongo_url, mongo_options)
  end

  def collection(name)
    client[name.to_sym]
  end

  private

  def mongo_url
    ENV.fetch('MONGO_URL') { 'mongodb://localhost:27017/jarvisapp' }
  end

  def mongo_options
    {
      database: ENV.fetch('MONGO_DB', 'jarvisapp'),
      user: ENV['MONGO_USER'],
      password: ENV['MONGO_PASSWORD'],
      server_selection_timeout: 2,
      connect_timeout: 2,
      socket_timeout: 2
    }
  end
end
