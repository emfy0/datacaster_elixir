defmodule Datacaster.TerminatorTest do
  use ExUnit.Case

  use Datacaster
  import DatacasterTestHelper

  alias Datacaster.{
    Success,
    Error
  }

  test "Raiser raises error on unchecked schema" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar))
      )
    end

    assert run_caster(caster, %{foo: :foo, bar: :bar, extra: "any"}) == %Error.Map{
      errors: %{
        "extra" => Error.new("should be absent", checked_context(["foo", "bar"], "any"))
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

    assert run_caster(caster, %{foo: :foo, bar: :bar, extra: "any"}) ==
      Success.new(%{"foo" => :foo, "bar" => :bar})
  end
end
