defmodule NasaFuelCalculator.Fuel do
  @moduledoc "Pure domain logic for calculating fuel requirements across a flight path."

  @planets %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  def planets do
    [{:earth, "Earth"}, {:moon, "Moon"}, {:mars, "Mars"}]
  end

  def calculate_path(mass, steps) do
    steps
    |> Enum.reverse()
    |> Enum.reduce(mass, fn {action, planet}, current_mass ->
      current_mass + total_fuel_for_step(current_mass, action, planet)
    end)
    |> Kernel.-(mass)
    |> trunc()
  end

  def total_fuel_for_step(mass, action, planet) do
    gravity = @planets[planet]
    fuel = step_fuel(action, mass, gravity)

    if fuel <= 0 do
      0
    else
      fuel + total_fuel_for_step(fuel, action, planet)
    end
  end

  defp step_fuel(:launch, mass, gravity), do: fuel_for_launch(mass, gravity)
  defp step_fuel(:land, mass, gravity), do: fuel_for_landing(mass, gravity)

  defp fuel_for_launch(mass, gravity) do
    trunc(mass * gravity * 0.042 - 33)
  end

  defp fuel_for_landing(mass, gravity) do
    trunc(mass * gravity * 0.033 - 42)
  end
end
