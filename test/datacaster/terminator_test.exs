defmodule Datacaster.TerminatorTest do
  use ExUnit.Case

  use Datacaster

  alias Datacaster.{
    Success,
    Error,
    Executor
  }

  test "Raiser raises error on unchecked schema" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar))
      )
    end

    assert Executor.run(caster, %{foo: :foo, bar: :bar, extra: "any"}) == %Error.Map{
      errors: %{
        "extra" => %Error{
          error: "should be absent",
          context: nil
        }
      }
    }
  end

  test "Swapper sweep unchecked schema keys" do
    caster = Datacaster.choosy_schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar))
      )
    end

    assert Executor.run(caster, %{foo: :foo, bar: :bar, extra: "any"}) ==
      Success.new(%{"foo" => :foo, "bar" => :bar})
  end
end
