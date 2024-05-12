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
