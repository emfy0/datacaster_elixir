defmodule Datacaster.CasterDefinition do
  @keys [:definition, :name, :caller]

  @enforce_keys @keys
  defstruct @keys

  def init(type, caller, definition) do
    name_from_type =
      "#{type}"
      |> String.split(".")
      |> List.last()
      |> String.downcase()

    %__MODULE__{
      definition: struct!(type, definition),
      name: :"#{name_from_type}_#{System.unique_integer([:positive])}",
      caller: caller
    }
  end

  def to_function_definition(
    %__MODULE__{definition: caster, name: name, caller: caller}
  ) do
    apply(caster.__struct__, :to_function_definition, [caster, name, caller])
  end
end
