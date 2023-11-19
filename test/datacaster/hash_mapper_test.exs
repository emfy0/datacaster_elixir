defmodule Datacaster.HashSchemaTest do
  use ExUnit.Case

  # import DatacasterTestHelper
  use Datacaster

  alias Datacaster.{
    Error,
    Success,
    Executor,
    Context
  }

  def checked_context(val) do
    %{__datacaster__: %Context{checked_schema: val}}
  end

  test "it maps data" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar))
      )
    end

    assert Executor.run(caster, %{foo: :foo, bar: :bar}) == {Success.new(%{foo: :foo, bar: :bar}), checked_context([:foo, :bar])}
  end

  test "it works with nested structures" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar)),
        baz: hash_schema(
          qux: check(&(&1 == :qux))
        )
      )
    end

    assert Executor.run(caster, %{foo: :foo, bar: :bar, baz: %{qux: :qux}}) == {Success.new(%{foo: :foo, bar: :bar, baz: %{qux: :qux}}), checked_context([:foo, :bar, :baz])}
  end

  test "it returns error" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar)),
        baz: hash_schema(
          qux: check(&(&1 == :qux))
        )
      )
    end

    assert Executor.run(caster, %{foo: :foo, bar: :bar, baz: %{qux: :asd}}) == {
      %Error.Map{
        errors: %{
          baz: %Error.Map{
            errors: %{
              qux: %Error{
                error: "invalid",
                context: checked_context([])
              }
            }
          }
        }
      },
      checked_context([])
    }
  end

  test "it returns multiple errors" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar)),
        baz: hash_schema(
          qux: check(&(&1 == :qux)),
        )
      )
    end

    assert Executor.run(caster, %{foo: :asd, bar: :bar, baz: %{qux: :asd}}) == {
      %Error.Map{
        errors: %{
          foo: %Error{
            error: "invalid",
            context: checked_context([])
          },
          baz: %Error.Map{
            errors: %{
              qux: %Error{
                error: "invalid",
                context: checked_context([])
              }
            }
          }
        }
      },
      checked_context([])
    }
  end
end
