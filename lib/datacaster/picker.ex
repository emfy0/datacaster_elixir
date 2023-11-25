defmodule Datacaster.Picker do
  alias Datacaster.{Error, Success, Absent}

  def build(keys) do
    build_function(keys)
  end

  defp build_function(key) do
    fn (value, context) ->
      {
        Success.new(visitor(key).(value)),
        context
      }
    end
  end

  defp visitor(keys) when is_tuple(keys) do
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
              visitor(key).(acc)
          end
        end)
    end
  end

  defp visitor(keys) when is_list(keys) do
    fn
      value = %Error{} ->
        value
      value ->
        Enum.reduce(keys, [], fn (key, acc) ->
          case visitor(key).(value) do
            val = %Error{} ->
              val
            val ->
              acc ++ [val]
          end
        end)
    end
  end

  defp visitor(key) when is_integer(key) do
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
            Error.new("is not a collection")
        end
    end
  end

  defp visitor(key) when is_atom(key) do
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
            Error.new("is not a hash")
        end
    end
  end

  defp visitor(key) do
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
            Error.new("is not a hash")
        end
    end
  end
end
