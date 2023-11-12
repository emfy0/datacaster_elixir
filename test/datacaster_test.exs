defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  use Datacaster

  alias Datacaster.{Error, Success, Absent}

  def call_caster(caster, val, context) do
    caster.caster.(val, context)
  end

  describe "#cast" do
    test "creates caster with lambda" do
      caster = Datacaster.schema do
        cast(fn input ->
          Success.new(input[:foo] == context[:bar])
        end)
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {Success.new(true), %{bar: :bar}}
    end
    
    test "it works with & syntax" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1[:foo] == :bar)))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(true), %{bar: :baz}}
    end

    test "it works with & syntax and context" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1[:foo] == &2[:bar])))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {Success.new(true), %{bar: :bar}}
    end
  end

  describe "#check" do
    test "builds checker ok monad on success" do
      caster = Datacaster.schema do
        check("error", fn _ ->
          context == 2
        end)
      end

      assert call_caster(caster, 2, 2) == {%Success{value: 2}, 2}
      assert call_caster(caster, 3, 3) == {%Error{error: "error"}, 3}
    end
  end

  describe "definition syntax" do
    test "it works with > syntax" do
      caster = Datacaster.schema do
        check(&(&1[:foo] == :bar)) > check(fn -> context[:bar] == :baz end)
      end

      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(%{foo: :bar}), %{bar: :baz}}
    end

    test "it works with <> syntax" do
      caster = Datacaster.schema do
        check(&(&1[:foo] == :not_bar)) <> check(fn -> context[:bar] == :baz end)
      end

      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(%{foo: :bar}), %{bar: :baz}}
    end

    test "> operator works in lambdas" do
      caster = Datacaster.schema do
        check(fn input ->
          input > context
        end)
      end

      assert call_caster(caster, 3, 2) == {Success.new(3), 2}
    end
  end

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
  
      assert call_caster(caster, %{"foo" => ["bar", "baz"]}, "context") == {Success.new("bar", Absent]), "context"}
    end
  end
end
