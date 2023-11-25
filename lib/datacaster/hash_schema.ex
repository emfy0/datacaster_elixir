defmodule Datacaster.HashSchema do
  alias Datacaster.{
    Context,
    Picker,
    Predefined,
    Success,
    Error
  }

  def build(opts) do
    modified_casters = Enum.map(opts, fn ({key, caster_node}) ->
      picker = Picker.build(key)
      node_with_picker = Predefined.>(picker, caster_node)
      key_to_check = key_from_pick(key)

      {
        key_to_check,
        fn (value, context) ->
          node_with_picker.(value, context)
        end
      }
    end)

    fn (value, context) ->
      results = Enum.map(modified_casters, fn {key_to_check, caster} ->
        {result, _} = caster.(value, context)
        key =
          case key_to_check do
            [key] when is_bitstring(key) ->
              String.to_atom(key)
            [key] ->
              key
          end
        {key, result}
      end)

      failures = Enum.filter(results, fn {_key, result} ->
        case result do
          %Error{} ->
            true
          %Error.Map{} ->
            true
          %Error.List{} ->
            true
          %Success{} ->
            false
        end
      end)

      if length(failures) == 0 do
        result = Enum.reduce(results, %{}, fn {key, result}, acc ->
          %Success{value: value} = result
          Map.put(acc, key, value)
        end)

        keys_checked = results |> Enum.map(fn {key, _} -> key end)

        {Success.new(result), Context.check_key(context, keys_checked)}
      else
        result = Enum.reduce(failures, %Error.Map{}, fn {key, result}, acc ->
          Error.Map.add_key(acc, key, result)
        end)

        {result, context}
      end
    end
  end

  def key_from_pick(key) when is_tuple(key) do
    [elem(key, 0)]
  end

  def key_from_pick(key) when is_list(key), do: key
  def key_from_pick(key) when is_atom(key), do: [Atom.to_string(key)]
  def key_from_pick(key), do: [key]
end
