defmodule Datacaster.HashSchemaTest do
  use DatacasterTest

  describe "it works with lists and integers" do
    define_caster do
      pick([1, {2, 1}, 3])
    end

    test_caster "returns success" do
      assert run_caster(["0", "1", ["0", "1", "2", "3"], "3"]) == ok(["1", "1", "3"])
    end

    test_caster "returns failure" do
      assert run_caster(["0", "1", "2", "3"]) == error("is not a collection")
    end
  end

  describe "it works with tuples and integers" do
    define_caster do
      pick({0, 0, 0})
    end

    test_caster "returns success" do
      assert run_caster([[["0"], "1"], "2", "3"]) == ok("0")
    end

    test_caster "returns failure for last" do
      assert run_caster([["0", "1"], "2", "3"]) == error("is not a collection")
    end

    test_caster "returns failure for first" do
      assert run_caster(["0", "2", "3"]) == error("is not a collection")
    end
  end

  describe "it works with maps and atoms" do
    define_caster do
      pick(:foo)
    end

    test_caster "returns success" do
      assert run_caster(%{foo: "bar"}) == ok("bar")
    end
  end

  describe "it works with maps and strings" do
    define_caster do
      pick("foo")
    end

    test_caster "returns success" do
      assert run_caster(%{"foo" => "bar"}) == ok("bar")
    end
  end

  describe "it works with nested maps with tuples" do
    define_caster do
      pick({"foo", :bar})
    end

    test_caster "returns success" do
      assert run_caster(%{"foo" => %{bar: "baz"}}) == ok("baz")
    end
  end

  describe "it works with nested maps with tuples with lists" do
    define_caster do
      pick({"foo", 0})
    end

    test_caster "returns success" do
      assert run_caster(%{"foo" => ["bar", "baz"]}) == ok("bar")
    end
  end

  describe "it works with nested maps with lists" do
    define_caster do
      pick(["foo", :bar])
    end

    test_caster "returns success" do
      assert run_caster(%{"foo" => %{bar: "baz"}}) == ok([%{bar: "baz"}, Datacaster.Absent.instance()])
    end
  end

  describe "it works with nested maps with lists with tuples" do
    define_caster do
      pick(["foo", 0])
    end

    test_caster "returns success" do
      assert run_caster(%{"foo" => ["bar", "baz"]}) == ok([["bar", "baz"], Datacaster.Absent.instance()])
    end
  end

  describe "it returns error on invalid input" do
    define_caster do
      pick(:foo)
    end

    test_caster "returns error" do
      assert run_caster(["bar", "baz"]) == error("is not a hash")
    end
  end

  describe "it returns error on invalid input with nested maps" do
    define_caster do
      pick({"foo", :bar})
    end

    test_caster "returns error" do
      assert run_caster(["foo", "bar"]) == error("is not a hash")
    end
  end

  describe "it works with nested structures" do
    define_caster do
      pick(["foo", {0, :bar}])
    end

    test_caster "returns success" do
      assert run_caster(%{
        "foo" => [
          %{bar: "baz"}, %{bar: "qux"}
        ]
      }) == ok([
        [%{bar: "baz"}, %{bar: "qux"}],
        Datacaster.Absent.instance()
      ])
    end
  end

  describe "it works with other nested structutes" do
    define_caster do
      pick({"foo", [:baz, :bar]})
    end

    test_caster "returns success" do
      assert run_caster(%{
        "foo" => %{
          baz: "baz", bar: "bar"
        }
      }) == ok([
        "baz", "bar"
      ])
    end
  end

  describe "it picks strings with atoms" do
    define_caster do
      pick({:foo, :bar})
    end

    test_caster "returns success" do
      assert run_caster(%{
        "foo" => %{
          "bar" => "bar"
        }
      }) == ok("bar")
    end
  end
end
