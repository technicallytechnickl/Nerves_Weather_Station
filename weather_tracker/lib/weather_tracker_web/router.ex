defmodule WeatherTrackerWeb.Router do
  use WeatherTrackerWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/api", WeatherTrackerWeb do
    pipe_through(:api)

    post("/weather-conditions", WeatherConditionsController, :create)
  end

  # Enable Swoosh mailbox preview in development
  if Application.compile_env(:weather_tracker, :dev_routes) do
    scope "/dev" do
      pipe_through([:fetch_session, :protect_from_forgery])

      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
