import Config

config :delivery_sim, Tokens.Repo,
  database: "delivery",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :delivery_sim, ecto_repos: [Tokens.Repo]

config :delivery_sim, Sim,
  auth0_client_id: System.get_env("AUTH0_CLIENT_ID"),
  auth0_client_secret: System.get_env("AUTH0_CLIENT_SECRET"),
  auth0_client_token: System.get_env("AUTH0_CLIENT_TOKEN")

config :logger, level: :debug

config :hackney, use_default_pool: false
