defmodule NasaFuelCalculatorWeb.MissionLiveTest do
  use NasaFuelCalculatorWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  # Counts only step wrapper divs (id="step-<digits>"), not step-form-<digits>
  defp count_steps(html) do
    Regex.scan(~r/id="step-\d+\"/, html) |> length()
  end

  defp fill_mass(view, mass) do
    view
    |> form("[phx-change='validate-mass']", mission: %{mass: mass})
    |> render_change()
  end

  defp extract_step_ids(view) do
    Regex.scan(~r/name="step_id" value="(\d+)"/, render(view), capture: :all_but_first)
    |> List.flatten()
  end

  describe "mount" do
    test "renders the page with initial state", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "NASA Fuel Calculator"
      assert html =~ "Equipment Mass"
      assert html =~ "Flight Path"
      assert html =~ "Total Fuel Required"
    end

    test "starts with one launch step on Earth", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert count_steps(html) == 1
      assert html =~ ~r/value="launch"[^>]*selected/
      assert html =~ ~r/value="earth"[^>]*selected/
    end

    test "result defaults to --", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "--"
    end
  end

  describe "validate-mass" do
    test "valid mass shows fuel result", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = fill_mass(view, "28801")

      refute html =~ ">--<"
    end

    test "zero mass shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = fill_mass(view, "0")

      assert html =~ "must be a positive number"
    end

    test "negative mass shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = fill_mass(view, "-5")

      assert html =~ "must be a positive number"
    end

    test "empty mass shows required error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = fill_mass(view, "")

      assert html =~ "mass is required"
    end

    test "Apollo 11 single step launch Earth shows correct fuel", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = fill_mass(view, "28801")

      assert html =~ "19,772"
    end
  end

  describe "add-step" do
    test "adds a new step row", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("button", "+ Add Step") |> render_click()

      assert count_steps(render(view)) == 2
    end

    test "alternates action from launch to land", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      html = view |> element("button", "+ Add Step") |> render_click()

      assert html =~ ~r/value="land"[^>]*selected/
    end

    test "remove button is disabled with one step", %{conn: conn} do
      {:ok, _view, html} = live(conn, ~p"/")

      assert html =~ "disabled"
    end

    test "remove button is enabled with multiple steps", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("button", "+ Add Step") |> render_click()
      html = render(view)

      refute html =~ "disabled"
    end
  end

  describe "remove-step" do
    test "removes a step", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("button", "+ Add Step") |> render_click()
      assert count_steps(render(view)) == 2

      [first_id | _] = extract_step_ids(view)
      view |> element("[phx-value-id='#{first_id}']") |> render_click()

      assert count_steps(render(view)) == 1
    end

    test "recalculates result after removal", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      fill_mass(view, "28801")
      view |> element("button", "+ Add Step") |> render_click()

      [first_id | _] = extract_step_ids(view)
      view |> element("[phx-value-id='#{first_id}']") |> render_click()
      html = render(view)

      assert count_steps(html) == 1
      assert html =~ "13,447"
    end
  end

  describe "update-step" do
    test "changing planet recalculates result", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      fill_mass(view, "28801")
      result_earth = render(view)

      [step_id | _] = extract_step_ids(view)

      view
      |> form("#step-form-#{step_id}", %{action: "launch", planet: "moon"})
      |> render_change()

      result_moon = render(view)

      refute result_earth == result_moon
    end
  end

  describe "reset" do
    test "clears steps back to one", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("button", "+ Add Step") |> render_click()
      view |> element("button", "+ Add Step") |> render_click()
      assert count_steps(render(view)) == 3

      view |> element("button", "Reset") |> render_click()
      assert count_steps(render(view)) == 1
    end

    test "clears result back to --", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      fill_mass(view, "28801")
      refute render(view) =~ ">--<"

      view |> element("button", "Reset") |> render_click()
      assert render(view) =~ "--"
    end
  end

  describe "step validation" do
    test "shows error for consecutive same actions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      view |> element("button", "+ Add Step") |> render_click()

      # Second step is land — change it to launch to trigger consecutive error
      [_first_id, second_id | _] = extract_step_ids(view)

      html =
        view
        |> form("#step-form-#{second_id}", %{action: "launch", planet: "earth"})
        |> render_change()

      assert html =~ "Cannot have two consecutive"
    end

    test "blocks result when step errors exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      fill_mass(view, "28801")
      view |> element("button", "+ Add Step") |> render_click()

      [_first_id, second_id | _] = extract_step_ids(view)

      html =
        view
        |> form("#step-form-#{second_id}", %{action: "launch", planet: "earth"})
        |> render_change()

      assert html =~ "--"
    end

    test "shows error when launch planet differs from last land planet", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/")

      # Step 1: launch earth, Step 2: land moon, Step 3: launch earth (should error)
      view |> element("button", "+ Add Step") |> render_click()
      view |> element("button", "+ Add Step") |> render_click()

      [_first_id, second_id, third_id | _] = extract_step_ids(view)

      view
      |> form("#step-form-#{second_id}", %{action: "land", planet: "moon"})
      |> render_change()

      html =
        view
        |> form("#step-form-#{third_id}", %{action: "launch", planet: "earth"})
        |> render_change()

      assert html =~ "Must launch from Moon"
    end
  end
end
