defmodule Datacaster.IfClauseTest do
  use ExUnit.Case

  use Datacaster
  import DatacasterTestHelper


  alias Datacaster.{
    Success,
    Error
  }
  
  test "it returns success" do
    caster = Datacaster.schema do
      on(
        check(&(&1 == :foo)),
        then: check(&(&1 == :foo)),
        else: check(&(&1 == :bar))
      )
    end

    assert run_caster(caster, :foo) == Success.new(:foo)
    assert run_caster(caster, :bar) == Success.new(:bar)
  end

  test "it returns error" do
    caster = Datacaster.schema do
      on(
        check(&(&1 == :foo)),
        then: check(&(&1 == :foo)),
        else: check(&(&1 == :bar))
      )
    end

    assert run_caster(caster, :baz) == Error.new("invalid", checked_context([], :baz))
  end

  test "it works with nested structures" do
    caster = Datacaster.schema do
      with_kind = hash_schema(kind: string())

      person = hash_schema(
        name: string(),
        age: integer()
      ) * with_kind

      bank = hash_schema(
        name: string(),
        address: string()
      ) * with_kind

      on(
        hash_schema(kind: check(&(&1 == "person"))),
        then: person,
        else: bank
      )
    end

    assert run_caster(caster, %{kind: "person", name: "John", age: 30}) == Success.new(
      %{"kind" => "person", "name" => "John", "age" =>  30}
    )
    assert run_caster(caster, %{kind: "bank", name: "Bank", address: "Street"}) == Success.new(
      %{"kind" => "bank", "name" => "Bank", "address" => "Street"}
    )
    assert run_caster(caster, %{kind: "person", name: "John", age: "not_int"}) == %Error.Map{
      errors: %{
        "age" => %Error{
          error: "should be an integer",
          context: checked_context([], "not_int")
        }
      }
    }
  end
end
