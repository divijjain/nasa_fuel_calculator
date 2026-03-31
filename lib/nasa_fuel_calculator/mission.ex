defmodule NasaFuelCalculator.Mission do
  @moduledoc "Public API for fuel calculations. Delegates to the Fuel domain module."

  alias NasaFuelCalculator.Fuel

  @type planet :: :earth | :moon | :mars
  @type step_action :: :launch | :land
  @type step :: {step_action(), planet()}

  @spec planets() :: [{planet(), String.t()}]
  defdelegate planets(), to: Fuel

  @spec calculate_path(number(), [step()]) :: non_neg_integer()
  defdelegate calculate_path(mass, steps), to: Fuel

  @spec total_fuel_for_step(number(), step_action(), planet()) :: non_neg_integer()
  defdelegate total_fuel_for_step(mass, action, planet), to: Fuel
end
