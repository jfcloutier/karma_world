# Karma World

Karma World is a virtual environment for virtual robots. It recreates, as an approximation, the physical environment in which the robots will actively learn in their attempt to survive.

The robot will run on a  wall-enclosed surface made out of luminous tiles. Each tile's luminosity and color can be changed programmatically.
There will also be static obstacles, other than the walls, that the robot will need to avoid bumping into.

There will always (often?) be one green patch of tiles of adjustable size that represent a source of food. The robot replenishes itself by spending time on this food patch. The other tiles will be of a "neutral" color but will be brighter the closer they are to the "food" patch.

The robot can detect the luminance and color of the surface it's on. It will need to learn to go up a luminosity gradient to reliably find the food it needs to survive
(just like E. Coli swims up a glucose gradient).

Once the robot has cumulatively spent enough time on the food patch, the patch will change to a "neutral" color (the food is all eaten up) and a new green patch will appear randomly somewhere else. The luminosity gradient will change to now "point to" the new location of the food.

This way a robot will inhabit a world  that changes because of a latent generative process it tries to model, and also because of its own (grazing) behavior.

## About

A simulated environment for karma agents.

Karma World

* exposes a JSON API to serve requests from `karma_body` to register sensors and actuators, and to simulate sensing and actuating
* implemenets a LiveView app to monitor agents navigating the virtual environment it defines

## API

put "/register_body/:body_name", WorldController, :register_body
post "/register_device/:body_name", WorldController, :register_device
get "/sense/body/:body_name/device/:device_id/sense/:sense", WorldController, :sense
put "/set_motor_control/body/:body_name/device/:device_id/control/:control/value/:value", WorldController, :set_motor_control
get "/actuate/body/:body_name/device/:device_id/action/:action", WorldController, :actuate

Body of /register_device/...

``` elixir
  %{
    "body_name" => robot_name,
    "device_id" => device_id,
    "device_class" => device_class,
    "device_type" => device_type,
    "properties" => properties
  }
```

## Quick test

Start Karma Body in a terminal (it will start in virtual mode):

```shell
> cd ./karma_body
> iex -S mix phx.server
```

Start Karma World in a terminal

```shell
> cd ./karma_world
> iex -S mix phx.server
```

Move the robot about from yet another terminal by copy and pasting any of these blocks of commands

```shell
# FORWARD
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outA/spin
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outB/spin
wget -q -O - http://127.0.0.1:4000/api/execute_actions

# RIGHT
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outA/spin
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outB/reverse_spin
wget -q -O - http://127.0.0.1:4000/api/execute_actions

# LEFT
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outA/reverse_spin
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outB/spin
wget -q -O - http://127.0.0.1:4000/api/execute_actions

# BACKWARD
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outA/reverse_spin
wget -q -O -  http://127.0.0.1:4000/api/actuate/tacho_motor-outB/reverse_spin
wget -q -O - http://127.0.0.1:4000/api/execute_actions

```
