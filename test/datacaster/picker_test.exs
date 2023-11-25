defmodule Datacaster.PickerTest do
  use ExUnit.Case

  use Datacaster
  alias Datacaster.{Error, Success, Absent, Executor}

  describe "pick" do
    test "it works with lists and integers" do
      caster = Datacaster.schema do
        pick([1, 2, 3])
      end
  
      assert Executor.run(caster, ["0", "1", "2", "3"], %{}) == Success.new(["1", "2", "3"])
    end

    test "it works with tuples and integers" do
      caster = Datacaster.schema do
        pick({0, 0})
      end
  
      assert Executor.run(caster, [["0", "1"], "2", "3"], %{}) == Success.new("0")
    end

    test "it works with maps and atoms" do
      caster = Datacaster.schema do
        pick(:foo)
      end
  
      assert Executor.run(caster, %{foo: "bar"}, %{}) == Success.new("bar")
    end

    test "it works with maps and strings" do
      caster = Datacaster.schema do
        pick("foo")
      end
  
      assert Executor.run(caster, %{"foo" => "bar"}, %{}) == Success.new("bar")
    end

    test "it works with nested maps with tuples" do
      caster = Datacaster.schema do
        pick({"foo", :bar})
      end
  
      assert Executor.run(caster, %{"foo" => %{bar: "baz"}}, %{}) == Success.new("baz")
    end

    test "it works with nested maps with tuples with lists" do
      caster = Datacaster.schema do
        pick({"foo", 0})
      end
  
      assert Executor.run(caster, %{"foo" => ["bar", "baz"]}, %{}) == Success.new("bar")
    end

    test "it works with nested maps with lists" do
      caster = Datacaster.schema do
        pick(["foo", :bar])
      end
  
      assert Executor.run(caster, %{"foo" => %{bar: "baz"}}, %{}) == Success.new([%{bar: "baz"}, Absent])
      assert Executor.run(caster, %{"foo" => %{bar: "baz"}}, %{}) == Success.new([%{bar: "baz"}, Absent])
    end

    test "it works with nested maps with lists with tuples" do
      caster = Datacaster.schema do
        pick(["foo", 0])
      end
      assert Executor.run(caster, %{"foo" => ["bar", "baz"]}, %{}) == Success.new([["bar", "baz"], Absent])
    end

    test "it returns error on invalid input" do
      caster = Datacaster.schema do
        pick(:foo)
      end
      assert Executor.run(caster, ["bar", "baz"], %{}) == Error.new("is not a hash")
    end

    test "it returns error on invalid input with nested maps" do
      caster = Datacaster.schema do
        pick({"foo", :bar})
      end
      assert Executor.run(caster, ["foo", "bar"], %{}) == Error.new("is not a hash")
    end

    test "it works with nested structures" do
      caster = Datacaster.schema do
        pick(["foo", {0, :bar}])
      end

      assert(Executor.run(caster,
        %{
          "foo" => [
            %{bar: "baz"}, %{bar: "qux"}
          ]
        }, %{}) == Success.new([
            [%{bar: "baz"}, %{bar: "qux"}],
            Absent
        ])
      )
    end

    test "it works with other nested structutes" do
      caster = Datacaster.schema do
        pick({"foo", [:baz, :bar]})
      end

      assert(Executor.run(caster,
        %{
          "foo" => %{
            baz: "baz", bar: "bar"
          }
        }, %{}) == Success.new([
            "baz", "bar"
        ])
      )
    end

    test "it picks strings with atoms" do
      caster = Datacaster.schema do
        pick({:foo, :bar})
      end

      assert(Executor.run(caster,
        %{
          "foo" => %{
            "bar" => "bar"
          }
        }, %{}) == Success.new("bar")
      )
    end
  end
end
