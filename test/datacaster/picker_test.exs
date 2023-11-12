defmodule Datacaster.PickerTest do
  use ExUnit.Case

  import DatacasterTestHelper

  use Datacaster
  alias Datacaster.{Error, Success, Absent}

  describe "pick" do
    test "it works with lists and integers" do
      caster = Datacaster.schema do
        pick([1, 2, 3])
      end
  
      assert call_caster(caster, ["0", "1", "2", "3"], "context") == {Success.new(["1", "2", "3"]), "context"}
    end

    test "it works with tuples and integers" do
      caster = Datacaster.schema do
        pick({0, 0})
      end
  
      assert call_caster(caster, [["0", "1"], "2", "3"], "context") == {Success.new("0"), "context"}
    end

    test "it works with maps and atoms" do
      caster = Datacaster.schema do
        pick(:foo)
      end
  
      assert call_caster(caster, %{foo: "bar"}, "context") == {Success.new("bar"), "context"}
    end

    test "it works with maps and strings" do
      caster = Datacaster.schema do
        pick("foo")
      end
  
      assert call_caster(caster, %{"foo" => "bar"}, "context") == {Success.new("bar"), "context"}
    end

    test "it works with nested maps with tuples" do
      caster = Datacaster.schema do
        pick({"foo", :bar})
      end
  
      assert call_caster(caster, %{"foo" => %{bar: "baz"}}, "context") == {Success.new("baz"), "context"}
    end

    test "it works with nested maps with tuples with lists" do
      caster = Datacaster.schema do
        pick({"foo", 0})
      end
  
      assert call_caster(caster, %{"foo" => ["bar", "baz"]}, "context") == {Success.new("bar"), "context"}
    end

    test "it works with nested maps with lists" do
      caster = Datacaster.schema do
        pick(["foo", :bar])
      end
  
      assert call_caster(caster, %{"foo" => %{bar: "baz"}}, "context") == {Success.new([%{bar: "baz"}, Absent]), "context"}
    end

    test "it works with nested maps with lists with tuples" do
      caster = Datacaster.schema do
        pick(["foo", 0])
      end
  
      assert call_caster(caster, %{"foo" => ["bar", "baz"]}, "context") == {Success.new([["bar", "baz"], Absent]), "context"}
    end

    test "it returns error on invalid input" do
      caster = Datacaster.schema do
        pick(:foo)
      end
  
      assert call_caster(caster, ["bar", "baz"], "context") == {Error.new("is not a hash"), "context"}
    end

    test "it returns error on invalid input with nested maps" do
      caster = Datacaster.schema do
        pick({"foo", :bar})
      end
  
      assert call_caster(caster, ["foo", "bar"], "context") == {Error.new("is not a hash"), "context"}
    end

    test "it works with nested structures" do
      caster = Datacaster.schema do
        pick(["foo", {0, :bar}])
      end

      assert(call_caster(caster,
        %{
          "foo" => [
            %{bar: "baz"}, %{bar: "qux"}
          ]
        }, "context") == {
          Success.new([
            [%{bar: "baz"}, %{bar: "qux"}],
            Absent
          ]), "context"
        }
      )
    end

    test "it works with other nested structutes" do
      caster = Datacaster.schema do
        pick({"foo", [:baz, :bar]})
      end

      assert(call_caster(caster,
        %{
          "foo" => %{
            baz: "baz", bar: "bar"
          }
        }, "context") == {
          Success.new([
            "baz", "bar"
          ]), "context"
        }
      )
    end
  end
end
