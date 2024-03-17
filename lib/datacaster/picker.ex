defmodule Datacaster.Picker do
  alias Datacaster.{Error, Success, Absent, Context}

  def key_from_pick(key) when is_tuple(key), do: elem(key, 0)
  def key_from_pick(key) when is_list(key), do: hd(key)
  def key_from_pick(key) when is_atom(key), do: Atom.to_string(key)
  def key_from_pick(key), do: key

  def build(keys) do
    build_function(keys)
  end

  defp build_function(key) do
    fn (value, context) ->
      {
        Success.new(visitor(key, context).(value)),
        context
      }
    end
  end

  defp visitor(keys, context) when is_tuple(keys) do
    keys = Tuple.to_list(keys)

    fn
      value = %Error{} ->
        value
      value ->
        Enum.reduce(keys, value, fn (key, acc) ->
          case acc do
            val = Absent ->
              val
            _ ->
              visitor(key, context).(acc)
          end
        end)
    end
  end

  defp visitor(keys, context) when is_list(keys) do
    fn
      value = %Error{} ->
        value
      value ->
        Enum.reduce(keys, [], fn (key, acc) ->
          case visitor(key, context).(value) do
            val = %Error{} ->
              val
            val ->
              acc ++ [val]
          end
        end)
    end
  end

  defp visitor(key, context) when is_integer(key) do
    fn 
      value = %Error{} ->
        value
      value ->
        cond do
          is_map(value) -> 
            Map.get(value, key, Absent)
          is_list(value) ->
            Enum.at(value, key, Absent)
          is_tuple(value) and key >= 0 ->
            if key < tuple_size(value) do
              elem(value, key)
            else
              Absent
            end
          true ->
            Error.new("is not a collection", context |> Context.put_error(value))
        end
    end
  end

  defp visitor(key, context) when is_atom(key) do
    fn
      value = %Error{} ->
        value
      value ->
        cond do
          is_map(value) -> 
            Map.get(value, key, Map.get(value, Atom.to_string(key), Absent))
          Keyword.keyword?(value) ->
            Keyword.get(value, key, Keyword.get(value, Atom.to_string(key), Absent))
          true ->
            Error.new("is not a hash", context |> Context.put_error(value))
        end
    end
  end

  defp visitor(key, context) do
    fn
      value = %Error{} ->
        value
      value ->
        cond do
          is_map(value) -> 
            Map.get(value, key, Absent)
          Keyword.keyword?(value) ->
            Keyword.get(value, key, Absent)
          true ->
            Error.new("is not a hash", context |> Context.put_error(value))
        end
    end
  end
end
