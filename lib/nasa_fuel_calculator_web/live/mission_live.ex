defmodule NasaFuelCalculatorWeb.MissionLive do
  use NasaFuelCalculatorWeb, :live_view

  import Ecto.Changeset

  alias NasaFuelCalculator.Fuel

  @types %{mass: :float}

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, initial_assigns())}
  end

  @impl true
  def handle_event("validate-mass", %{"mission" => params}, socket) do
    cs = changeset(params)
    parsed_mass = if cs.valid?, do: get_field(cs, :mass), else: nil

    {:noreply,
     socket
     |> assign(form: to_form(cs, action: :validate, as: :mission), parsed_mass: parsed_mass)
     |> assign_steps(socket.assigns.steps)}
  end

  def handle_event("add-step", _params, socket) do
    %{steps: steps} = socket.assigns

    next_action = steps |> List.last() |> Map.fetch!(:action) |> alternate_action()

    default_planet =
      if next_action == :launch do
        steps
        |> Enum.filter(&(&1.action == :land))
        |> List.last()
        |> case do
          nil -> :earth
          step -> step.planet
        end
      else
        :earth
      end

    {:noreply, assign_steps(socket, steps ++ [new_step(next_action, default_planet)])}
  end

  def handle_event("reset", _params, socket) do
    {:noreply, assign(socket, initial_assigns())}
  end

  def handle_event("remove-step", %{"id" => id}, socket) do
    steps = Enum.reject(socket.assigns.steps, &(to_string(&1.id) == id))
    {:noreply, assign_steps(socket, steps)}
  end

  def handle_event("update-step", %{"step_id" => step_id} = params, socket) do
    updates =
      params
      |> Map.take(["action", "planet"])
      |> Map.new(fn {k, v} -> {String.to_existing_atom(k), String.to_existing_atom(v)} end)

    steps =
      Enum.map(socket.assigns.steps, fn step ->
        if to_string(step.id) == step_id, do: Map.merge(step, updates), else: step
      end)

    {:noreply, assign_steps(socket, steps)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-base-200 py-10">
      <div class="max-w-2xl mx-auto space-y-6 px-4">
        <h1 class="text-3xl font-bold text-center">NASA Fuel Calculator</h1>

        <%!-- Mass Input --%>
        <div class="card bg-base-100 shadow-md">
          <div class="card-body">
            <h2 class="card-title">Equipment Mass</h2>
            <.form for={@form} phx-change="validate-mass">
              <.input
                field={@form[:mass]}
                type="number"
                label="Mass (kg)"
                placeholder="e.g. 28801"
                step="any"
              />
            </.form>
          </div>
        </div>

        <%!-- Flight Path --%>
        <div class="card bg-base-100 shadow-md">
          <div class="card-body">
            <h2 class="card-title">Flight Path</h2>
            <div class="space-y-3">
              <div
                :for={{step, index} <- Enum.with_index(@steps)}
                id={"step-#{step.id}"}
                class="flex flex-col gap-1"
              >
                <div class="flex items-center gap-3">
                  <span class="text-sm font-medium w-5 text-right opacity-50">
                    {index + 1}.
                  </span>
                  <form id={"step-form-#{step.id}"} phx-change="update-step" class="contents">
                    <input type="hidden" name="step_id" value={step.id} />
                    <select
                      class={[
                        "select select-bordered flex-1",
                        @step_errors[step.id] && "select-error"
                      ]}
                      name="action"
                    >
                      <option value="launch" selected={step.action == :launch}>Launch</option>
                      <option value="land" selected={step.action == :land}>Land</option>
                    </select>
                    <select
                      class={[
                        "select select-bordered flex-1",
                        @step_errors[step.id] && "select-error"
                      ]}
                      name="planet"
                    >
                      <option
                        :for={{key, label} <- Fuel.planets()}
                        id={"#{step.id}-#{key}"}
                        value={key}
                        selected={step.planet == key}
                      >
                        {label}
                      </option>
                    </select>
                  </form>
                  <button
                    class="btn btn-ghost btn-sm text-error"
                    phx-click="remove-step"
                    phx-value-id={step.id}
                    disabled={length(@steps) == 1}
                  >
                    ✕
                  </button>
                </div>
                <p :if={@step_errors[step.id]} class="text-error text-xs pl-8">
                  {@step_errors[step.id]}
                </p>
              </div>
            </div>
            <div class="card-actions mt-4 justify-between">
              <button class="btn btn-outline btn-sm" phx-click="add-step">
                + Add Step
              </button>
              <button class="btn btn-ghost btn-sm text-error" phx-click="reset">
                Reset
              </button>
            </div>
          </div>
        </div>

        <%!-- Result --%>
        <div class="card bg-base-100 shadow-md">
          <div class="card-body">
            <h2 class="card-title">Total Fuel Required</h2>
            <div class="stats stats-horizontal w-full">
              <div class="stat">
                <div class="stat-title">Equipment mass</div>
                <div class="stat-value text-base-content/60">
                  {if @parsed_mass, do: format_number(trunc(@parsed_mass)), else: "--"}
                </div>
                <div class="stat-desc">kg</div>
              </div>
              <div class="stat">
                <div class="stat-title">Fuel required</div>
                <div class="stat-value text-primary">
                  {if @result, do: format_number(@result), else: "--"}
                </div>
                <div class="stat-desc">kg</div>
              </div>
            </div>
            <div :if={@breakdown != []} class="overflow-x-auto mt-4">
              <table class="table table-sm">
                <thead>
                  <tr>
                    <th>#</th>
                    <th>Action</th>
                    <th>Planet</th>
                    <th class="text-right">Fuel (kg)</th>
                  </tr>
                </thead>
                <tbody>
                  <tr
                    :for={{{step, fuel}, index} <- Enum.with_index(@breakdown)}
                    id={"breakdown-#{step.id}"}
                  >
                    <td class="opacity-50">{index + 1}</td>
                    <td>{humanize_atom(step.action)}</td>
                    <td>{humanize_atom(step.planet)}</td>
                    <td class="text-right font-mono">{format_number(fuel)}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  defp initial_assigns do
    [
      page_title: "NASA Fuel Calculator",
      form: to_form(changeset(%{}), as: :mission),
      parsed_mass: nil,
      steps: [new_step(:launch, :earth)],
      step_errors: %{},
      result: nil,
      breakdown: []
    ]
  end

  defp assign_steps(socket, steps) do
    step_errors = validate_steps(steps)
    socket = assign(socket, steps: steps, step_errors: step_errors)

    case {socket.assigns.parsed_mass, step_errors} do
      {nil, _} ->
        assign(socket, result: nil, breakdown: [])

      {_, errors} when map_size(errors) > 0 ->
        assign(socket, result: nil, breakdown: [])

      {mass, _} ->
        {result, breakdown} = calculate(mass, steps)
        assign(socket, result: result, breakdown: breakdown)
    end
  end

  defp validate_steps(steps) do
    steps
    |> Enum.zip([nil | steps])
    |> Enum.reduce(%{}, fn {step, prev}, errors ->
      cond do
        is_nil(prev) ->
          errors

        prev.action == step.action ->
          Map.put(errors, step.id, "Cannot have two consecutive #{step.action} steps")

        step.action == :launch && prev.action == :land && prev.planet != step.planet ->
          Map.put(
            errors,
            step.id,
            "Must launch from #{humanize_atom(prev.planet)} where you last landed"
          )

        true ->
          errors
      end
    end)
  end

  defp new_step(action, planet) do
    %{id: :erlang.unique_integer([:positive]), action: action, planet: planet}
  end

  defp alternate_action(:launch), do: :land
  defp alternate_action(:land), do: :launch

  defp changeset(params) do
    {%{}, @types}
    |> cast(params, [:mass])
    |> validate_required([:mass], message: "mass is required")
    |> validate_number(:mass, greater_than: 0, message: "must be a positive number")
  end

  defp calculate(mass, steps) do
    path = Enum.map(steps, &{&1.action, &1.planet})
    total = Fuel.calculate_path(mass, path)

    breakdown =
      steps
      |> Enum.reverse()
      |> Enum.reduce({mass, []}, fn step, {current_mass, acc} ->
        fuel = Fuel.total_fuel_for_step(current_mass, step.action, step.planet)
        {current_mass + fuel, [{step, fuel} | acc]}
      end)
      |> elem(1)

    {total, breakdown}
  end

  defp humanize_atom(atom), do: atom |> to_string() |> String.capitalize()

  defp format_number(n) do
    n
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(",")
    |> String.reverse()
  end
end
