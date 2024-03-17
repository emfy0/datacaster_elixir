defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  use Datacaster
  alias Datacaster.{Error, Success, Executor, Context}

  def build_context(val, error \\ nil) do
    Map.put(val, :__datacaster__, Context.new())
    |> Context.put_error(error)
  end

  describe "#cast" do
    test "creates caster with lambda" do
      caster = Datacaster.schema do
        cast(fn input ->
          Success.new(input["foo"] == context[:bar])
        end)
      end
   
      assert Executor.run(caster, %{foo: :bar}, %{bar: :bar}) == Success.new(true)
    end
    
    test "it works with & syntax" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1["foo"] == :bar)))
      end
   
      assert Executor.run(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(true)
    end

    test "it works with & syntax and context" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1["foo"] == &2[:bar])))
      end
   
      assert Executor.run(caster, %{foo: :bar}, %{bar: :bar}) == Success.new(true)
    end
  end

  describe "#check" do
    test "builds checker ok monad on success" do
      caster = Datacaster.schema do
        check("error", fn _ ->
          context.a == 2
        end)
      end

      assert Executor.run(caster, 2, %{a: 2}) == %Success{value: 2}
      assert Executor.run(caster, 3, %{a: 3}) == %Error{error: "error", context: build_context(%{a: 3}, 3)}
    end
  end

  describe "definition syntax" do
    test "it works with > syntax" do
      caster = Datacaster.schema do
        check(&(&1["foo"] == :bar)) > check(fn -> context[:bar] == :baz end)
      end

      assert Executor.run(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "it works with <> syntax" do
      caster = Datacaster.schema do
        check(&(&1["foo"] == :not_bar)) <> check(fn -> context[:bar] == :baz end)
      end

      assert Executor.run(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "> operator works in lambdas" do
      caster = Datacaster.schema do
        check(fn input ->
          input > context.a
        end)
      end

      assert Executor.run(caster, 3, %{a: 2}) == Success.new(3)
    end

    test "it sets context on error" do
      caster = Datacaster.schema do
        check(fn input ->
          context = Map.put(context, :b, 3)

          input < context.a
        end)
      end

      assert Executor.run(caster, 3, %{a: 2}) == Error.new("invalid", build_context(%{a: 2, b: 3}, 3))
    end
  end

  describe "#hash" do
    test "it works with hash" do
      caster = Datacaster.schema(do: hash())

      assert Executor.run(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "it returns error on non-hash" do
      caster = Datacaster.schema(do: hash())

      assert Executor.run(caster, 1, %{bar: :baz}) == Error.new("should be a hash", build_context(%{bar: :baz}, 1))
    end
  end

  describe "#included_in" do
    test "it works with included_in" do
      caster = Datacaster.schema do
        included_in([1, 2, 3])
      end

      assert Executor.run(caster, 1, %{bar: :baz}) == Success.new(1)
      assert Executor.run(caster, 4, %{bar: :baz}) == Error.new("should be included in [1, 2, 3]", build_context(%{bar: :baz}, 4))
    end
  end
end
