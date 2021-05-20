# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :helix_gym,
  ecto_repos: [HelixGym.Repo]

# Configures the endpoint
config :helix_gym, HelixGymWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "/pjLFEHaLfGZ3AszVIR68ZGqjFW0k+oEis5Qig6kgUuBYvs7oGBzhrhX1qtnY5OJ",
  render_errors: [view: HelixGymWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: HelixGym.PubSub,
  live_view: [signing_salt: "CbRo5ciH"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
