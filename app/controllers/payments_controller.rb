class PaymentsController < ApplicationController
  QUEUE = Concurrent::Queue.new
  PROCESSOR = Services::Processor.new(QUEUE).tap(&:start)

  def create
    body = params.body.read
    payment_data = JSON.parse(body, symbolize_names: true)

    payment_request = {
      correlationId: payment_data[:correlationId],
      amount: payment_data[:amount].to_f,
      requestedAt: Time.now.utc.iso8601(3)
    }

    QUEUE << payment_request
    render json: { message: 'Payment received for processing' }, status: :accepted
  end


  def summary
    from = params[:from]
    to = params[:to]

    query = {}
    query[:created_at] = {} if from || to
    query[:created_at][:"$gte"] = Time.parse(from) if from
    query[:created_at][:"$lte"] = Time.parse(to) if to

    payments = Mongoid.client(:default)[:payments].find(query)

    summary = {
      default: { totalRequests: 0, totalAmount: 0.0 },
      fallback: { totalRequests: 0, totalAmount: 0.0 }
    }

    payments.each do |payment|
      processor = payment.dig('processor_used')
      amount = payment.dig('amount').to_f

      if processor && summary[processor.to_sym]
        summary[processor.to_sym][:totalRequests] += 1
        summary[processor.to_sym][:totalAmount] += amount
      end
    end

    render json: {
      default: {
        totalRequests: summary[:default][:totalRequests],
        totalAmount: format('%.2f', summary[:default][:totalAmount])
      },
      fallback: {
        totalRequests: summary[:fallback][:totalRequests],
        totalAmount: format('%.2f', summary[:fallback][:totalAmount])
      }
    }
  end
end
