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
    # green
    food_color: 3,
    # how many tiles pad the center food tile to create a food patch
    food_padding: 1,
    # food is gone after 10 to 30 secs of eating
    food_duration_range: 10..30,
    # how far the scent of food travels (and affect ambient light)
    max_food_scent_distance_cm: 100,
    # tile data - height, beacon
    # "<obstacle height / 10><beacon orientation>|...."
    # _ = default, otherwise: obstacle in 0..9,  color is default color, ambient default ambient, beacon 1 orientation in [N, S, E, W], beacon 2 orientation in [n, s, e, w]

    tiles: [
      "__|__|__|__|__|__|__|__|1_|1_|1_|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|1_|1_|1_|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|1_|1S|1_|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|3_|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|3_|__|__|__|__|__|__|__|__|__|__|3_|3_|__|__|__|__|__",
      "__|__|3_|__|__|__|__|__|__|__|__|__|__|__|3_|__|__|__|__|__",
      "__|__|3_|__|__|__|__|__|__|__|__|__|__|__|3_|__|__|__|__|__",
      "__|__|3_|__|__|__|__|__|__|__|__|__|__|__|3_|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|1_|1n|1_|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|1_|1_|1_|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__",
      "__|__|1_|1_|1_|__|__|__|__|__|__|__|__|__|__|__|__|__|__|__"
      # ^--row 0, column 0
    ]
  ]

config :karma_world,
  starting_places: [
    # 0 is up/north, 90 is right/east, 180 is down/south, 270 is left/west
    [row: 5, column: 8, orientation: 0],
    [row: 15, column: 15, orientation: 180]
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
