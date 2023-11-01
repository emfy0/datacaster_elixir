defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  alias Datacaster.{Caster, Checker, Executor}

  defp caster_result(caster, input, context) do
    Executor.process(caster, input, context)
  end

  describe "#cast" do
    test "creates caster with lambda with arity 2" do
      caster = Caster.cast(fn (context, input) ->
        {:ok, context[:foo] == input[:baz]}
      end)
    
      assert caster_result(caster, %{foo: :bar}, %{baz: :bar}) == {:ok, true}
    end

    test "creates caster with lambda with arity 1" do
      caster = Caster.cast(fn (input) ->
        {:ok, input}
      end)
    
      assert caster_result(caster, %{foo: :bar}, %{}) == {:ok, %{foo: :bar}}
    end
  end

  describe "#check" do
    test "returns ok monad on success" do
      caster = Checker.check(fn (context, _) ->
        context == 2
      end)

      assert caster_result(caster, 2, 2) == {:ok, true}
    end

    test "returns error monad on failure" do
      caster = Checker.check(fn (context, _) ->
        context == 2
      end)

      assert caster_result(caster, 1, 2) == {:error, nil, %{value: 1}}
    end

    test "passes datacaster meta" do
      caster = Checker.check(fn (_) ->
        {:__datacaster__, %{gettext: %{foo: :bar}}}
      end)

      assert caster_result(caster, 1, 2) == {:error, nil, %{value: 1, foo: :bar}}
    end
  end
end
