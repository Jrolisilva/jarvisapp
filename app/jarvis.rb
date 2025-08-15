# frozen_string_literal: true
require 'sinatra/base'
require 'json'
require_relative '../services/processor'

class Jarvis < Sinatra::Base
  configure do
    set :queue, Queue.new
    set :processor, Services::Processor.new(settings.queue)
    settings.processor.start
  end

  post '/payments' do
    begin
      request.body.rewind
      data = JSON.parse(request.body.read, symbolize_names: true)

      required_keys = %i[id amount primary fallback]
      unless required_keys.all? { |key| data.key?(key) }
        halt 400, { error: 'Missing required payment data' }.to_json
      end

      payload = {
        id: data[:id],
        amount: data[:amount],
        timestamp: Time.now.utc
      }

      settings.queue << { payload: payload, primary: data[:primary], fallback: data[:fallback] }
      status 202
      { message: 'Payment processing started' }.to_json
    rescue JSON::ParserError => e
      halt 400, { error: 'Invalid JSON format' }.to_json
    rescue StandardError => e
      halt 500, { error: "Internal server error: #{e.message}" }.to_json
    end
  end

  get '/health' do
    content_type :json
    status 200
    { status: 'ok', timestamp: Time.now.utc }.to_json
  end
end
