
workers Integer(ENV.fetch("WEB_CONCURRENCY", 2))

threads_count = Integer(ENV.fetch("MAX_THREADS", 5))
threads threads_count, threads_count

preload_app!

port ENV.fetch("PORT", 4567)
environment ENV.fetch("RACK_ENV", "development")

# Important when using preload_app! with DB connections like Mongo
on_worker_boot do
  require_relative '../app/mongo_connection'
  MongoConnection.instance
end
