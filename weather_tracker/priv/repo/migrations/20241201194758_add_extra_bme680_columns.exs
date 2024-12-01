defmodule WeatherTracker.Repo.Migrations.AddExtraBme680Columns do
  use Ecto.Migration

  def up do
    alter table(:weather_conditions) do
      add(:dew_point_c, :decimal)
      add(:humidity_rh, :decimal)
      add(:gas_resistance_ohms, :decimal)
    end
  end

  def down do
    alter table(:weather_conditions) do
      remove(:dew_point_c)
      remove(:humidity_rh)
      remove(:gas_resistance_ohms)
    end
  end
end
