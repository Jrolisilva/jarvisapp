require 'net/http'
require 'uri'
require 'json'

module Services
  class Request
    def self.post(processor, payment, timeout)
      uri = URI("http://payment-processor-#{processor}:8080/payments")

      Net::HTTP.start(uri.host, uri.port) do |http|
        http.open_timeout = timeout
        http.read_timeout = timeout

        request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
        request.body = payment.to_json
        response = http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          puts "Payment processed successfully: #{response.body}"
        else
          puts "Failed to process payment: #{response.code} #{response.message}"
        end
      end
    rescue Net::OpenTimeout, Net::ReadTimeout => e
      puts "Request timed out: #{processor} - #{e.message}"
      false
    rescue StandardError => e
      puts "An error occurred: #{processor} - #{e.message}"
      false
    end
  end
end
