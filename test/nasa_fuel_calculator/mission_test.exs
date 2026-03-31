defmodule NasaFuelCalculator.MissionTest do
  use ExUnit.Case, async: true

  alias NasaFuelCalculator.Mission

  describe "planets/0" do
    test "returns all three planets" do
      assert Mission.planets() == [{:earth, "Earth"}, {:moon, "Moon"}, {:mars, "Mars"}]
    end

    test "planet labels are properly capitalized strings" do
      for {_key, label} <- Mission.planets() do
        assert is_binary(label)
        assert label == String.capitalize(label)
      end
    end
  end

  describe "total_fuel_for_step/3" do
    test "landing 28801 kg on Earth accumulates to 13447" do
      assert Mission.total_fuel_for_step(28_801, :land, :earth) == 13_447
    end

    test "launching 28801 kg from Earth" do
      assert Mission.total_fuel_for_step(28_801, :launch, :earth) == 19_772
    end

    test "landing on Moon uses lower gravity" do
      assert Mission.total_fuel_for_step(28_801, :land, :moon) == 2_046
    end

    test "launching from Moon uses lower gravity" do
      assert Mission.total_fuel_for_step(28_801, :launch, :moon) == 3_459
    end

    test "landing on Mars" do
      assert Mission.total_fuel_for_step(28_801, :land, :mars) == 4_622
    end

    test "launching from Mars" do
      assert Mission.total_fuel_for_step(28_801, :launch, :mars) == 8_353
    end

    test "mass of 0 returns 0" do
      assert Mission.total_fuel_for_step(0, :launch, :earth) == 0
    end

    test "negative mass returns 0" do
      assert Mission.total_fuel_for_step(-1_000, :launch, :earth) == 0
    end

    test "mass too small to produce positive fuel returns 0" do
      # fuel_for_launch(1, 9.807) = trunc(1 * 9.807 * 0.042 - 33) = trunc(-32.58) = -32
      assert Mission.total_fuel_for_step(1, :launch, :earth) == 0
    end
  end

  describe "calculate_path/2" do
    test "Apollo 11 — launch Earth, land Moon, launch Moon, land Earth" do
      steps = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      assert Mission.calculate_path(28_801, steps) == 51_898
    end

    test "Mars mission — launch Earth, land Mars, launch Mars, land Earth" do
      steps = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
      assert Mission.calculate_path(14_606, steps) == 33_388
    end

    test "Passenger Ship — full 6-step path" do
      steps = [
        {:launch, :earth},
        {:land, :moon},
        {:launch, :moon},
        {:land, :mars},
        {:launch, :mars},
        {:land, :earth}
      ]

      assert Mission.calculate_path(75_432, steps) == 212_161
    end

    test "single step" do
      assert Mission.calculate_path(28_801, [{:land, :earth}]) == 13_447
    end

    test "empty steps returns 0" do
      assert Mission.calculate_path(28_801, []) == 0
    end

    test "mass of 0 returns 0" do
      assert Mission.calculate_path(0, [{:launch, :earth}]) == 0
    end
  end
end
