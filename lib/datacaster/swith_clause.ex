defmodule Datacaster.SwithClause do
  alias Datacaster.{
    Predefined,
    Success,
    Picker,
    Error,
    Context
  }

  def build(statement, on_caluses, else_clause) do
    statement = build_pick_from_shortcut(statement)

    on_caluses = Enum.map(on_caluses, fn {caluse, action} ->
      {build_compare_from_shortcut(caluse), action}
    end)

    fn (initial_value, context) ->
      {result, context} = statement.(initial_value, context)

      case result do
        %Success{value: value} ->
          find_clause(on_caluses, else_clause, initial_value, value, context)
        _ ->
          resurn_error(else_clause, initial_value, context)
      end
    end
  end

  defp find_clause(on_clauses, else_clause, initial_value, value, context) do
    result = Enum.reduce_while(on_clauses, nil, fn {caluse, action}, _acc ->
      {caluse_result, _context} = caluse.(value, context)

      case caluse_result do
        %Success{} ->
          {:halt, action.(initial_value, context)}
        _ ->
          {:cont, nil}
      end
    end)

    case result do
      nil ->
        resurn_error(else_clause, value, context)
      _ ->
        result
    end
  end

  defp resurn_error(else_clause, value, context) do
    if is_function(else_clause) do
      else_clause.(value, context)
    else
      {Error.new("is invalid", context |> Context.put_error(value)), context}
    end
  end

  defp build_pick_from_shortcut(key) when is_function(key), do: key
  defp build_pick_from_shortcut(key) do
    Predefined.>(Picker.build(key), fn (value, context) ->
      key_to_check = Picker.key_from_pick(key)
      {Success.new(value), Context.check_key(context, key_to_check)}
    end)
  end

  defp build_compare_from_shortcut(key) when is_function(key), do: key
  defp build_compare_from_shortcut(key) when is_atom(key) do
    Predefined.<>(Predefined.compare(key), Predefined.compare(Atom.to_string(key)))
  end
  defp build_compare_from_shortcut(key), do: Predefined.compare(key)
end
