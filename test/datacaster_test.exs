defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  import DatacasterTestHelper

  use Datacaster
  alias Datacaster.{Error, Success}

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
end
