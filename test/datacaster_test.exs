defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  use Datacaster
  alias Datacaster.{Error, Success, Context}

  def build_context(val) do
    Map.put(val, :__datacaster__, Context.new())
  end

  def call_caster(caster, input, context) do
    caster.(input, build_context(context))
  end

  describe "#cast" do
    test "creates caster with lambda" do
      caster = Datacaster.schema do
        cast(fn input ->
          Success.new(input[:foo] == context[:bar])
        end)
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {Success.new(true), build_context(%{bar: :bar})}
    end
    
    test "it works with & syntax" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1[:foo] == :bar)))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(true), build_context(%{bar: :baz})}
    end

    test "it works with & syntax and context" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1[:foo] == &2[:bar])))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {Success.new(true), build_context(%{bar: :bar})}
    end
  end

  describe "#check" do
    test "builds checker ok monad on success" do
      caster = Datacaster.schema do
        check("error", fn _ ->
          context.a == 2
        end)
      end

      assert call_caster(caster, 2, %{a: 2}) == {%Success{value: 2}, build_context(%{a: 2})}
      assert call_caster(caster, 3, %{a: 3}) == {%Error{error: "error", context: build_context(%{a: 3})}, build_context(%{a: 3})}
    end
  end

  describe "definition syntax" do
    test "it works with > syntax" do
      caster = Datacaster.schema do
        check(&(&1[:foo] == :bar)) > check(fn -> context[:bar] == :baz end)
      end

      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(%{foo: :bar}), build_context(%{bar: :baz})}
    end

    test "it works with <> syntax" do
      caster = Datacaster.schema do
        check(&(&1[:foo] == :not_bar)) <> check(fn -> context[:bar] == :baz end)
      end

      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {Success.new(%{foo: :bar}), build_context(%{bar: :baz})}
    end

    test "> operator works in lambdas" do
      caster = Datacaster.schema do
        check(fn input ->
          input > context.a
        end)
      end

      assert call_caster(caster, 3, build_context(%{a: 2})) == {Success.new(3), build_context(%{a: 2})}
    end

    test "it sets context on error" do
      caster = Datacaster.schema do
        check(fn input ->
          context = Map.put(context, :b, 3)

          input < context.a
        end)
      end

      assert call_caster(caster, 3, build_context(%{a: 2})) == {Error.new("invalid", build_context(%{a: 2, b: 3})), build_context(%{a: 2})}
    end
  end
end
