Rails.application.routes.draw do
  post '/payments', to: 'payments#create'
  get '/payments-summary', to: 'payments#summary'
end
