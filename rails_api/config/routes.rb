Rails.application.routes.draw do
  get "/ping", to: "application#ping"
  post "/readings", to: "readings#create"
  get "/devices/:id/latest_timestamp", to: "devices#latest_timestamp"
  get "/devices/:id/total_count", to: "devices#total_count"
end
