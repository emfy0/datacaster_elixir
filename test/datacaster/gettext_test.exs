defmodule Datacaster.GettextTest do
  use ExUnit.Case

  use Datacaster

  alias Datacaster.Executor

  test "it works with nested structures" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: compare("test"),
        age: check("test", &(&1 > 18))
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", age: 15, test: "not_test"}) == {
      :error, %{ "age" => "test translation", "test" => "should be equal to \"test\"" }
    }
  end

  test "in works with setted gettext options" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          gettext_opts!(var1: "test1", var2: "test2")
          x == "test"
        end)
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => "my error translation test1 test2" }
    }
  end
end
