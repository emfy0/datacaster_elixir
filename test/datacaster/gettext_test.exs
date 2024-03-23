defmodule Datacaster.GettextTest do
  use ExUnit.Case

  use Datacaster

  alias Datacaster.Executor

  test "generates propper messages with nested strictures" do
    caster = Datacaster.schema do
      person = hash_schema(
        name: string(),
        age: check("test", &(&1 > 18))
      )

      hash_schema(
        kind: string(),
        person: person
      )
    end

    assert Executor.validate(caster, %{kind: "person", person: %{name: "John", age: 15}}) == {
      :error, %{ "person" => %{ "age" => ["test translation"] } }
    }
  end

  test "it works with nested structures" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: compare("test"),
        age: check("test", &(&1 > 18))
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", age: 15, test: "not_test"}) == {
      :error, %{ "age" => ["test translation"], "test" => ["should be equal to \"test\""] }
    }
  end

  test "it works with setted gettext options" do
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
      :error, %{ "test" => ["my error translation test1 test2"] }
    }
  end

  test "it works with outside setted gettext options" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          x == "test"
        end) |> gettext_opts(var1: "test1", var2: "test2")
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => ["my error translation test1 test2"] }
    }
  end

  test "it works with setted gettext namespace" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          gettext_namespace!("my_namespace")
          x == "test"
        end)
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => ["my error"] }
    }
  end

  test "it works with outside setted gettext namespace" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          x == "test"
        end) |> gettext_namespace("my_namespace")
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => ["my error"] }
    }
  end

  test "it works with setted gettext context" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          gettext_context!("my_context")
          x == "test"
        end)
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => ["my error"] }
    }
  end

  test "it works with outside setted gettext context" do
    caster = Datacaster.schema do
      hash_schema(
        name: string(),
        test: check("my error", fn x ->
          x == "test"
        end) |> gettext_context("my_context")
      )
    end

    assert Executor.validate(caster, %{kind: "person", name: "John", test: "not_test"}) == {
      :error, %{ "test" => ["my error"] }
    }
  end
end
