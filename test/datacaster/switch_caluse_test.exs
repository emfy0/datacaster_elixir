defmodule Datacaster.SwitchCaluseTest do
  use ExUnit.Case

  use Datacaster
  import DatacasterTestHelper


  alias Datacaster.{
    Success,
    Error,
    Executor
  }
  
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

      switch(
        :kind,
        on: %{
          person: person,
          bank: bank
        },
        else: cast(fn (_) -> Error.new("HELLO") end)
      )
    end

    assert Executor.run(caster, %{kind: "person", name: "John", age: 30}) == Success.new(
      %{"kind" => "person", "name" => "John", "age" =>  30}
    )
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street"}) == Success.new(
      %{"kind" => "bank", "name" => "Bank", "address" => "Street"}
    )
    assert Executor.run(caster, %{kind: "person", name: "John", age: "not_int"}) == %Error.Map{
      errors: %{
        "age" => %Error{
          error: "should be an integer",
          context: checked_context(["kind"], "not_int")
        }
      }
    }
    assert Executor.run(caster, %{kind: "???", name: "Bank", address: "Street"}) == Error.new("HELLO", checked_context(["kind"], "???"))
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street", extra: "some"}) == %Error.Map{
      errors: %{
        "extra" => %Error{
          error: "should be absent",
          context: checked_context(["kind", "name", "address", "kind"], "some")
        }
      }
    }
  end

  test "it correctly sets visited values for schema with shortcut definition" do
    caster = Datacaster.schema do
      person = hash_schema(
        name: string(),
        age: integer()
      )

      bank = hash_schema(
        name: string(),
        address: string()
      )

      switch(
        :kind,
        on: %{
          person: person,
          bank: bank
        },
        else: cast(fn (_) -> Error.new("HELLO") end)
      )
    end

    assert Executor.run(caster, %{kind: "person", name: "John", age: 30}) == Success.new(
      %{"kind" => "person", "name" => "John", "age" =>  30}
    )
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street"}) == Success.new(
      %{"kind" => "bank", "name" => "Bank", "address" => "Street"}
    )
    assert Executor.run(caster, %{kind: "person", name: "John", age: "not_int"}) == %Error.Map{
      errors: %{
        "age" => %Error{
          error: "should be an integer",
          context: checked_context(["kind"], "not_int")
        }
      }
    }
    assert Executor.run(caster, %{kind: "???", name: "Bank", address: "Street"}) == Error.new("HELLO", checked_context(["kind"], "???"))
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street", extra: "some"}) == %Error.Map{
      errors: %{
        "extra" => Error.new("should be absent", checked_context(["kind", "name", "address"], "some"))
      }
    }
  end

  test "it works with datacaster matchers" do
    caster = Datacaster.schema do
      person = hash_schema(
        name: string(),
        age: integer()
      )

      bank = hash_schema(
        name: string(),
        address: string()
      )

      switch(
        hash_schema(kind: string()) > pick(:kind),
        on: %{
          person: person,
          bank: bank
        },
        else: cast(fn (_) -> Error.new("HELLO") end)
      )
    end

    assert Executor.run(caster, %{kind: "person", name: "John", age: 30}) == Success.new(
      %{"kind" => "person", "name" => "John", "age" =>  30}
    )
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street"}) == Success.new(
      %{"kind" => "bank", "name" => "Bank", "address" => "Street"}
    )
    assert Executor.run(caster, %{kind: "person", name: "John", age: "not_int"}) == %Error.Map{
      errors: %{
        "age" => %Error{
          error: "should be an integer",
          context: checked_context(["kind"], "not_int")
        }
      }
    }
    assert Executor.run(caster, %{kind: "???", name: "Bank", address: "Street"}) == Error.new("HELLO", checked_context(["kind"], "???"))
    assert Executor.run(caster, %{kind: "bank", name: "Bank", address: "Street", extra: "some"}) == %Error.Map{
      errors: %{
        "extra" => Error.new("should be absent", checked_context(["kind", "name", "address"], "some"))
      }
    }
  end
end
