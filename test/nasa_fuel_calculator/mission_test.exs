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
      assert Mission.total_fuel_for_step(28_801, :land, :earth) == {:ok, 13_447}
    end

    test "launching 28801 kg from Earth" do
      assert Mission.total_fuel_for_step(28_801, :launch, :earth) == {:ok, 19_772}
    end

    test "landing on Moon uses lower gravity" do
      assert Mission.total_fuel_for_step(28_801, :land, :moon) == {:ok, 1_535}
    end

    test "launching from Moon uses lower gravity" do
      assert Mission.total_fuel_for_step(28_801, :launch, :moon) == {:ok, 2_024}
    end

    test "landing on Mars" do
      assert Mission.total_fuel_for_step(28_801, :land, :mars) == {:ok, 3_874}
    end

    test "launching from Mars" do
      assert Mission.total_fuel_for_step(28_801, :launch, :mars) == {:ok, 5_186}
    end

    test "mass of 0 returns error" do
      assert Mission.total_fuel_for_step(0, :launch, :earth) ==
               {:error, "mass must be a positive number"}
    end

    test "negative mass returns error" do
      assert Mission.total_fuel_for_step(-1_000, :launch, :earth) ==
               {:error, "mass must be a positive number"}
    end

    test "invalid action returns error" do
      assert Mission.total_fuel_for_step(1_000, :fly, :earth) == {:error, "invalid action :fly"}
    end

    test "invalid planet returns error" do
      assert Mission.total_fuel_for_step(1_000, :launch, :venus) ==
               {:error, "invalid planet :venus"}
    end
  end

  describe "calculate_path/2" do
    test "Apollo 11 — launch Earth, land Moon, launch Moon, land Earth" do
      steps = [{:launch, :earth}, {:land, :moon}, {:launch, :moon}, {:land, :earth}]
      assert Mission.calculate_path(28_801, steps) == {:ok, 51_898}
    end

    test "Mars mission — launch Earth, land Mars, launch Mars, land Earth" do
      steps = [{:launch, :earth}, {:land, :mars}, {:launch, :mars}, {:land, :earth}]
      assert Mission.calculate_path(14_606, steps) == {:ok, 33_388}
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

      assert Mission.calculate_path(75_432, steps) == {:ok, 212_161}
    end

    test "single step" do
      assert Mission.calculate_path(28_801, [{:land, :earth}]) == {:ok, 13_447}
    end

    test "mass of 0 returns error" do
      assert Mission.calculate_path(0, [{:launch, :earth}]) ==
               {:error, "mass must be a positive number"}
    end

    test "negative mass returns error" do
      assert Mission.calculate_path(-100, [{:launch, :earth}]) ==
               {:error, "mass must be a positive number"}
    end

    test "empty steps returns error" do
      assert Mission.calculate_path(28_801, []) == {:error, "steps must not be empty"}
    end

    test "consecutive same actions returns error" do
      steps = [{:launch, :earth}, {:launch, :moon}]
      assert {:error, msg} = Mission.calculate_path(28_801, steps)
      assert msg =~ "consecutive"
    end

    test "launch from wrong planet returns error" do
      steps = [{:launch, :earth}, {:land, :moon}, {:launch, :earth}]
      assert {:error, msg} = Mission.calculate_path(28_801, steps)
      assert msg =~ "must launch from"
    end

    test "invalid planet in steps returns error" do
      assert {:error, msg} = Mission.calculate_path(28_801, [{:launch, :venus}])
      assert msg =~ "invalid planet"
    end
  end
end
