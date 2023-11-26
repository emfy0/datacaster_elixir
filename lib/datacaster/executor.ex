defmodule Datacaster.Executor do
  def run(caster, value, context \\ %{}) do
    value = if is_map(value), do: stringify_keys(value), else: value

    context = Map.merge(context, %{__datacaster__: Datacaster.Context.new})
    {result, _context} = caster.(value, context)
    result
  end

  def stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {stringify_key(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  def stringify_keys(val), do: val

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: key
end
