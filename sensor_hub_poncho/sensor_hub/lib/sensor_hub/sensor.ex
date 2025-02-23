defmodule SensorHub.Sensor do

  require Logger

  defstruct [:name, :fields, :read, :convert, :calculate]

  def new(name, meas \\ %{}) do
    %__MODULE__{
      read: read_fn(name),
      convert: convert_fn(name),
      calculate: calculate_fn(name, meas),
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

  def calculate_fn(SGP30, %{}), do: fn meas -> %{abs_hum: "SGP30"} end
  def calculate_fn(VEML6030, %{}), do: fn meas -> %{abs_hum: "VEML"} end
  def calculate_fn(BME680, meas), do: fn meas -> absolute_humidity(meas) end


  defp absolute_humidity(bme_meas) do
    # https://www.calctool.org/atmospheric-thermodynamics/absolute-humidity#actual-vapor-pressure
    # absolute humidity in g/m3

    case map_size(bme_meas) do

      0 -> %{}
      _ ->
        t_k = to_k(bme_meas[:temperature_c])

        t_tc = t_k  / 647.096

        tau_calc = -7.85951783 * t_tc + 1.84408259 * t_tc**1.5 - 11.7866497 * t_tc**3 + 22.6807411 * t_tc**3.5 - 15.9618719 * t_tc**4 + 1.80122502 * t_tc**7.5

        ps = 22.064e6 * :math.exp( 1 / t_tc * tau_calc)

        pa = ps * bme_meas[:humidity_rh]/100

        ah = pa / (461.5 * t_k)

        %{abs_hum: ah * 1000}

    end
  end

  defp to_k(temp_C) do
    temp_C + 273.15
  end

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
