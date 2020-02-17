import Config

config :delivery_sim, Tokens.Repo,
  database: "delivery_sim",
  username: "aleksey",
  password: "",
  hostname: "localhost"

config :delivery_sim, ecto_repos: [Tokens.Repo]

config :logger, level: :debug

config :hackney, use_default_pool: false
