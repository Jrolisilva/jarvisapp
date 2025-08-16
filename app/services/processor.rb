module Services
  class Processor
    DEFAULT_TIMEOUT = 0.2
    FALLBACK_TIMEOUT = 0.1
    MAX_RETRIES = 5

    def initialize(queue)
      @queue = queue
      @collection = Mongoid.client(:default)[:payments]
      @default_timeout = ENV.fetch('DEFAULT_TIMEOUT', DEFAULT_TIMEOUT).to_f
      @fallback_timeout = ENV.fetch('FALLBACK_TIMEOUT', FALLBACK_TIMEOUT).to_f
      @max_retries = ENV.fetch('MAX_RETRIES', MAX_RETRIES).to_i
    end

    def start
      @queue = Concurrent::Array.new
      Thread.new do
        loop do
          payment = @queue.shift
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
        timeout = processor == primary ? @default_timeout : @fallback_timeout

        puts "Attempt #{attempt + 1} for processor: #{processor} with timeout: #{timeout}"
        tried_times << processor
        success = Services::Request.post(processor, payload, timeout)
        if success
          persist_result(payload, processor)
          puts "Payment processed successfully with #{processor}"
          break
        else
          puts "Payment processing failed with #{processor}"
          if attempt < @max_retries - 1
            puts "Retrying with #{fallback} after failure with #{processor}"
          end
        end
      end
    end

    def persist_result(payload, processor_used)
      @collection.insert_one({
        correlation_id: payload[:correlationId],
        processor_used: processor_used.to_s,
        amount: payload[:amount],
        requested_at: payload[:requestedAt],
      })
    end
  end
end
