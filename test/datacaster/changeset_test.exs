defmodule Datacaster.ChangesetTest do
  use ExUnit.Case

  use Datacaster

  alias Datacaster.{
    Executor
  }

  defp changeset_module, do:
    Application.get_env(:datacaster, :changeset_module)

  test "it returns changeset with valid data" do
    caster = Datacaster.schema do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar)),
        baz: hash_schema(
          qux: check(&(&1 == :qux))
        )
      )
    end

    assert Executor.validate_to_changeset(caster, %{foo: :foo, bar: :bar, baz: %{qux: :asd}}) == {
      :error,
      struct(changeset_module(), %{
        action: :validate,
        changes: %{
          foo: :foo,
          bar: :bar,
          baz: struct(changeset_module(), %{
            action: nil,
            changes: %{
              qux: :asd
            },
            errors: [qux: {"invalid", [validation: :invalid]}],
            data: %{},
            valid?: false
          })
        },
        errors: [],
        data: %{},
        valid?: false
      })
    }
  end
end
