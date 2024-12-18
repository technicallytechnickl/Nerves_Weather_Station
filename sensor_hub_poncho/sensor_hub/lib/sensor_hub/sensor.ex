defmodule SensorHub.Sensor do
  defstruct [:name, :fields, :read, :convert]

  def new(name) do
    %__MODULE__{
      read: read_fn(name),
      convert: convert_fn(name),
      fields: fields(name),
      name: name
    }
  end

  def fields(SGP30), do: [:co2_eq_ppm, :tvoc_ppb]

  def fields(BME680),
    do: [
      :temperature_c,
      :pressure_pa,
      :humidity_rh,
      :gas_resistance_ohms,
      :dew_point_c,
      :altitude_m
    ]

  def fields(VEML6030), do: [:light_lumens]

  def read_fn(SGP30), do: fn -> SGP30.state() end
  def read_fn(BME680), do: fn -> BMP280.measure(BME680) end
  def read_fn(VEML6030), do: fn -> Veml6030.get_measurement() end

  def convert_fn(SGP30) do
    fn reading ->
      Map.take(reading, [:co2_eq_ppm, :tvoc_ppb])
    end
  end

  def convert_fn(BME680) do
    fn reading ->
      case reading do
        {:ok, measurement} ->
          Map.take(measurement, [
            :temperature_c,
            :pressure_pa,
            :humidity_rh,
            :gas_resistance_ohms,
            :dew_point_c,
            :altitude_m
          ])

        _ ->
          %{}
      end
    end
  end

  def convert_fn(VEML6030) do
    fn data -> %{light_lumens: data} end
  end

  def measure(sensor) do
    sensor.read.()
    |> sensor.convert.()
  end
end
