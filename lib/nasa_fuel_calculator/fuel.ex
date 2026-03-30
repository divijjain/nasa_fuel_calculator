defmodule NasaFuelCalculator.Fuel do
  @moduledoc "Pure domain logic for calculating fuel requirements across a flight path."

  @planets %{
    earth: 9.807,
    moon: 1.62,
    mars: 3.711
  }

  @type planet :: :earth | :moon | :mars
  @type step_action :: :launch | :land
  @type step :: {step_action(), planet()}

  @spec planets() :: [{planet(), String.t()}]
  def planets do
    [{:earth, "Earth"}, {:moon, "Moon"}, {:mars, "Mars"}]
  end

  @spec calculate_path(number(), [step()]) :: non_neg_integer()
  def calculate_path(mass, steps) do
    steps
    |> Enum.reverse()
    |> Enum.reduce(mass, fn {action, planet}, current_mass ->
      current_mass + total_fuel_for_step(current_mass, action, planet)
    end)
    |> Kernel.-(mass)
  end

  @spec total_fuel_for_step(number(), step_action(), planet()) :: non_neg_integer()
  def total_fuel_for_step(mass, action, planet) do
    gravity = @planets[planet]
    fuel = step_fuel(action, mass, gravity)

    if fuel <= 0 do
      0
    else
      fuel + total_fuel_for_step(fuel, action, planet)
    end
  end

  @spec step_fuel(step_action(), number(), float()) :: integer()
  defp step_fuel(:launch, mass, gravity), do: fuel_for_launch(mass, gravity)
  defp step_fuel(:land, mass, gravity), do: fuel_for_landing(mass, gravity)

  @spec fuel_for_launch(number(), float()) :: integer()
  defp fuel_for_launch(mass, gravity) do
    trunc(mass * gravity * 0.042 - 33)
  end

  @spec fuel_for_landing(number(), float()) :: integer()
  defp fuel_for_landing(mass, gravity) do
    trunc(mass * gravity * 0.033 - 42)
  end
end
