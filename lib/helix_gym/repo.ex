defmodule HelixGym.Repo do
  use Ecto.Repo,
    otp_app: :helix_gym,
    adapter: Ecto.Adapters.Postgres
end
