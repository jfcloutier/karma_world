import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :karma_world, KarmaWorldWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Tjps85XW3s27VwaLN8ua2Od6jPVNeADRSdKzWK5nluro6J7oNmYV0Kt6EYoC8m8G",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
