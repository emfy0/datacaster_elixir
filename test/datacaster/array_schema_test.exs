defmodule Datacaster.ArraySchemaTest do
  use ExUnit.Case

  use Datacaster
  import DatacasterTestHelper

  alias Datacaster.{
    Error,
    Success,
    Executor
  }

  test "it returns success" do
    caster = Datacaster.schema do
      array_of(check(&(&1 == :foo)))
    end

    assert Executor.run(caster, [:foo, :foo]) == Success.new([:foo, :foo])
  end

  test "it returns error" do
    caster = Datacaster.schema do
      array_of(check(&(&1 == :foo)) * check(&(&1 == :bar)))
    end

    assert Executor.run(caster, [:foo, :baz]) == %Error.Map{
      errors: %{
        0 => %Error{
          error: "invalid",
          context: checked_context([])
        },
        1 => %Error.List{
          errors: [
            %Error{
              error: "invalid",
              context: checked_context([])
            },
            %Error{
              error: "invalid",
              context: checked_context([])
            }
          ]
        }
      }
    }
  end
end

