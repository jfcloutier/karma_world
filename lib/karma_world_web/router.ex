defmodule KarmaWorldWeb.Router do
  use KarmaWorldWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KarmaWorldWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KarmaWorldWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  scope "/api", KarmaWorldWeb do
    pipe_through :api

    put "/register_body/:body_name", WorldController, :register_body
    post "/register_device/:body_name", WorldController, :register_device
    get "/sense/body/:body_name/device/:device_id/sense/:sense", WorldController, :sense
    put "/set_motor_control/body/:body_name/device/:device_id/control/:control/value/:value", WorldController, :set_motor_control
    get "/actuate/body/:body_name/device/:device_id/action/:action", WorldController, :actuate
  end

  # Enable LiveDashboard in development
  if Application.compile_env(:karma_world, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: KarmaWorldWeb.Telemetry
    end
  end
end
