defmodule NasaFuelCalculator.Mission do
  @moduledoc "Public API for fuel calculations. Delegates to the Fuel domain module."

  alias NasaFuelCalculator.Fuel

  @type planet :: :earth | :moon | :mars
  @type step_action :: :launch | :land
  @type step :: {step_action(), planet()}

  @valid_planets Enum.map(Fuel.planets(), &elem(&1, 0))
  @valid_actions [:launch, :land]

  @spec planets() :: [{planet(), String.t()}]
  defdelegate planets(), to: Fuel

  @spec calculate_path(number(), [step()]) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def calculate_path(mass, steps) do
    with :ok <- validate_mass(mass),
         :ok <- validate_steps(steps) do
      {:ok, Fuel.calculate_path(mass, steps)}
    end
  end

  @spec total_fuel_for_step(number(), step_action(), planet()) ::
          {:ok, non_neg_integer()} | {:error, String.t()}
  def total_fuel_for_step(mass, action, planet) do
    with :ok <- validate_mass(mass),
         :ok <- validate_action(action),
         :ok <- validate_planet(planet) do
      {:ok, Fuel.total_fuel_for_step(mass, action, planet)}
    end
  end

  defp validate_mass(mass) when is_number(mass) and mass > 0, do: :ok
  defp validate_mass(_), do: {:error, "mass must be a positive number"}

  defp validate_steps([]), do: {:error, "steps must not be empty"}

  defp validate_steps(steps) when is_list(steps) do
    steps
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {{action, planet}, index}, :ok ->
      with :ok <- validate_action(action),
           :ok <- validate_planet(planet),
           :ok <- validate_step_sequence(steps, index) do
        {:cont, :ok}
      else
        {:error, _} = error -> {:halt, error}
      end
    end)
  end

  defp validate_steps(_), do: {:error, "steps must be a list"}

  defp validate_step_sequence(_steps, 0), do: :ok

  defp validate_step_sequence(steps, index) do
    {action, planet} = Enum.at(steps, index)
    {prev_action, prev_planet} = Enum.at(steps, index - 1)

    cond do
      prev_action == action ->
        {:error, "step #{index + 1}: cannot have two consecutive #{action} steps"}

      action == :launch and prev_action == :land and prev_planet != planet ->
        {:error, "step #{index + 1}: must launch from #{prev_planet} where you last landed"}

      true ->
        :ok
    end
  end

  defp validate_action(action) when action in @valid_actions, do: :ok
  defp validate_action(action), do: {:error, "invalid action #{inspect(action)}"}

  defp validate_planet(planet) when planet in @valid_planets, do: :ok
  defp validate_planet(planet), do: {:error, "invalid planet #{inspect(planet)}"}
end
