Rails.application.config.after_initialize do
  ActiveRecord::Schema.verbose = false

  # Need to load the schema when the app starts (since it's an in-memory db)
  load Rails.root.join("db/schema.rb")
end
