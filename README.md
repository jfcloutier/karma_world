# Karma World

**UNDER CONSTRUCTION**

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
