defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  use Datacaster

  def call_caster(caster, val, context) do
    caster.caster.(val, context)
  end

  describe "#cast" do
    test "creates caster with lambda" do
      caster = Datacaster.schema do
        cast(fn input ->
          {:ok, input[:foo] == context[:bar]}
        end)
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {{:ok, true}, %{bar: :bar}}
    end
    
    test "it works with & syntax" do
      caster = Datacaster.schema do
        cast(&(&1[:foo] == :bar))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :baz}) == {true, %{bar: :baz}}
    end

    test "it works with & syntax and context" do
      caster = Datacaster.schema do
        cast(&(&1[:foo] == &2[:bar]))
      end
   
      assert call_caster(caster, %{foo: :bar}, %{bar: :bar}) == {true, %{bar: :bar}}
    end
  end

  describe "#check" do
    test "builds checker ok monad on success" do
      caster = Datacaster.schema do
        check("error", fn _ ->
          context == 2
        end)
      end

      assert call_caster(caster, 2, 2) == %Datacaster.Success{value: 2, context: 2}
      assert call_caster(caster, 3, 3) == %Datacaster.Error{error: "error", context: 3}
    end
  end
end
