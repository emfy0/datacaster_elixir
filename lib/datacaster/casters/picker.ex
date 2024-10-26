defmodule Datacaster.Casters.Picker do
  alias Datacaster.Casters.Picker
  @keys [:keys]

  @enforce_keys @keys
  defstruct @keys

  def key_from_pick(key) when is_tuple(key), do: elem(key, 0)
  def key_from_pick(key) when is_list(key), do: hd(key)
  def key_from_pick(key) when is_atom(key), do: Atom.to_string(key)
  def key_from_pick(key), do: key

  use Datacaster.Result

  def to_function_definition(
    %__MODULE__{keys: keys}, name, caller
  ) do
    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(input, context) do
        Picker.pick(unquote(Macro.escape(keys)), input, context)
      end
    end
  end

  def pick(_keys, input = %Error{}, context) do
    {input, context}
  end

  def pick(keys, input, context) when is_tuple(keys) do
    keys
    |> Tuple.to_list()
    |> Enum.reduce_while(input, fn key, acc ->
      case acc do
        %Datacaster.Absent{} = val ->
          {:halt, {ok(val), context}}

        _ ->
          {r, c} = pick(key, acc, context)

          if r.ok? do
            {:cont, r.value}
          else
            {:halt, {r, c}}
          end
      end
    end)
    |> case do
      {r, c} -> {r, c}
      r -> {ok(r), context}
    end
  end

  def pick(keys, input, context) when is_list(keys) do
    picked_keys = Enum.map(keys, fn key -> pick(key, input, context) end)

    errors = Enum.filter(picked_keys, fn {r, _c} -> r.error? end)

    if length(errors) == 0 do
      result =
        picked_keys
        |> Enum.reduce([], fn {result, _c}, acc ->
          acc ++ [result.value]
        end)

      {ok(result), context}
    else
      {error, _context} = errors |> List.first()
      {error, context}
    end
  end

  def pick(key, input, context) when is_integer(key) do
    cond do
      is_map(input) -> 
        {
          Map.get(input, key, Datacaster.Absent.instance())
          |> ok(),
          context
        }
      is_list(input) ->
        {
          Enum.at(input, key, Datacaster.Absent.instance())
          |> ok(),
          context
        }
      is_tuple(input) and key >= 0 ->
        if key < tuple_size(input) do
          {
            elem(input, key)
            |> ok(),
            context
          }
        else
          {
            Datacaster.Absent.instance()
            |> ok(),
            context
          }
        end
      true ->
        {
          Error.new("is not a collection", Datacaster.Context.put_error(context, input)),
          context
        }
    end
  end

  def pick(key, input, context) when is_atom(key) do
    case input do
      value = %Error{} ->
        {value, context}
      value ->
        cond do
          is_map(value) ->
            stringified = Map.get(value, Atom.to_string(key), Datacaster.Absent.instance())

            {
              Map.get(value, key, stringified)
              |> ok(),
              context
            }
          Keyword.keyword?(value) ->
            stringified = Keyword.get(value, Atom.to_string(key), Datacaster.Absent.instance())

            {
              Keyword.get(value, key, stringified)
              |> ok(),
              context
            }
          true ->
            {
              Error.new("is not a hash", Datacaster.Context.put_error(context, value)),
              context
            }
        end
    end
  end

  def pick(key, input, context) do
    case input do
      value = %Error{} ->
        {value, context}
      value ->
        cond do
          is_map(value) -> 
            {
              Map.get(value, key, Datacaster.Absent.instance())
              |> ok(),
              context
            }
          Keyword.keyword?(value) ->
            {
              Keyword.get(value, key, Datacaster.Absent.instance())
              |> ok(),
              context
            }
          true ->
            {
              Error.new("is not a hash", Datacaster.Context.put_error(context, value)),
              context
            }
        end
    end
  end
end
