defmodule Datacaster.Terminator do
  alias Datacaster.{
    Success,
    Error,
  }

  def build(caster) do
    fn (value, context) -> {result, context} = caster.(value, context)

      case result do
        %Success{} ->
          process_schema(value, context, result)
        %Error{} ->
          {result, context}
        %Error.Map{} ->
          {result, context}
        %Error.List{} ->
          {result, context}
      end
    end
  end

  defp process_schema(value, context, result) do
    current_checked_schema = context.__datacaster__.checked_schema

    if need_to_check_schema?(current_checked_schema) do
      checked_schema(value, context, result, current_checked_schema)
    else
      {result, context}
    end
  end

  defp checked_schema(value, context, result, current_checked_schema) do
    case retrive_schema_from_value(value) do
      nil ->
        {result, context}
      schema ->
        diff = schema -- Enum.map(current_checked_schema, &normalize_atoms/1)

        if length(diff) == 0 do
          {result, context}
        else
          {
            Enum.reduce(diff, %Error.Map{}, fn key, acc ->
              Error.Map.add_key(acc, key, Error.new("should be absent"))
            end),
            context
          }
        end
    end
  end

  defp need_to_check_schema?(checked_schema) do
    length(checked_schema) > 0
  end

  defp retrive_schema_from_value(value) when is_map(value) do
    Map.keys(value) |> Enum.map(&normalize_atoms/1)
  end

  defp retrive_schema_from_value(value) do
    cond do
      Keyword.keyword?(value) ->
        Keyword.keys(value) |> Enum.map(&normalize_atoms/1)
      true ->
        nil
    end
  end

  defp normalize_atoms(value) when is_atom(value), do: Atom.to_string(value)
  defp normalize_atoms(value), do: value
end
