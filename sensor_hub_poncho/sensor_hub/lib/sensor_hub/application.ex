defmodule SensorHub.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias SensorHub.Sensor

  @impl true
  def start(_type, _args) do
    # [
    #   # Children for all targets
    #   # Starts a worker by calling: SensorHub.Worker.start_link(arg)
    #   # {SensorHub.Worker, arg},
    # ] ++ target_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SensorHub.Supervisor]
    Supervisor.start_link(target_children(), opts)
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp target_children() do
      [
        # Children that only run on the host during development or test.
        # In general, prefer using `config/host.exs` for differences.
        #
        # Starts a worker by calling: Host.Worker.start_link(arg)
        # {Host.Worker, arg},
      ]
    end
  else
    defp target_children() do
      [
        {BMP280, [i2c_address: 0x77, name: BME680]},
        {Veml6030, %{}},
        {SGP30, []},
        {Finch, name: WeatherTrackerClient},
        {
          Publisher,
          %{
            sensors: sensors(),
            weather_tracker_url: weather_tracker_url()
          }
        }
      ]
    end
  end

  defp sensors() do
    [Sensor.new(BME680), Sensor.new(VEML6030), Sensor.new(SGP30)]
  end

  defp weather_tracker_url() do
    Application.get_env(:sensor_hub, :weather_tracker_url)
  end
end
