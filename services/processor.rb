# frozen_string_literal: true
require 'concurrent-ruby'
require_relative '../services/request'
require_relative '../db/mongo_connection'

module Services
  class Processor
      DEFAULT_TIMEOUT = 0.2
      FALLBACK_TIMEOUT = 0.1
      MAX_RETRIES = 5

    def initialize(queue)
      @queue = queue
      @collection = MongoConnection.instance.collection('payments')
      @default_timeout = ENV.fetch('DEFAULT_TIMEOUT', 0.2).to_f
      @fallback_timeout = ENV.fetch('FALLBACK_TIMEOUT', 0.1).to_f
      @max_retries = ENV.fetch('MAX_RETRIES', 5).to_i
    end

    def start
      QUEUE = Concurrent::Array.new
      Thread.new do
        loop do
          payment = QUEUE.shift
          process_payment(payment) if payment
        rescue StandardError => e
          puts "Error processing payment: #{e.message}"
          next
        end
      end
    end

    def process_payment(payment)
      primary = payment[:primary]
      fallback = payment[:fallback]
      payload = payment[:payload]

      success = false
      tried_times = []

      @max_retries.times do |attempt|
        processor = attempt.even? ? primary : fallback
        timeout = processror == primary ? @default_timeout : @fallback_timeout

        puts "Attempt #{attempt + 1} for processor: #{processor} with timeout: #{timeout}"
        tried_times << processor
        success = Services::Request.post(processor, payload, timeout)
        break if success
      end

      persist_result(payload, tried_times, success)
    end

    def persist_result(payload, tried_times, success)
      @collection.insert_one({
        payload: payload,
        tried_times: tried_times,
        status: success ? 'success' : 'failure',
        created_at: Time.now.utc
      })
    end
  end
end
