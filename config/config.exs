# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :karma_world,
  playground: [
    default_ambient: 10,
    default_color: 7,
    tile_side_cm: 10,
    tiles_per_rotation: 0.5,
    degrees_per_motor_rotation: 45,
    tiles_per_motor_rotation: 0.5,
    # tile data - height, beacon, color, ambient
    # "<obstacle height * 10><beacon orientation><color><ambient * 10>|...."
    # _ = default, otherwise: obstacle in 0..9,  color in 0..7, ambient in 0..9, beacon_orientation in [N, S, E, W]

    tiles: [
      "____|____|____|____|____|____|____|____|1___|1___|1___|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|1___|1___|1___|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|1___|1S__|1___|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|__6_|__6_|__6_|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1|___1",
      "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|____|____|____|___1|___1|___1",
      "____|____|3___|____|____|____|____|____|____|____|____|____|____|3___|3___|____|____|____|___1|___1",
      "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|___1",
      "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|____",
      "____|____|3___|____|____|____|____|____|____|____|____|____|____|____|3___|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|____|___8|____|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|____|___6|___6|___6|____|____|____|____|____|____|____",
      "____|____|____|____|____|____|____|____|____|___4|___4|___4|___4|___4|____|____|____|____|____|____"
      # ^--row 0, column 0
    ]
  ]

config :karma_world,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :karma_world, KarmaWorldWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: KarmaWorldWeb.ErrorHTML, json: KarmaWorldWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: KarmaWorld.PubSub,
  live_view: [signing_salt: "lj4fX62T"]

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  karma_world: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  karma_world: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
