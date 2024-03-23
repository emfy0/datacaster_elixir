defmodule Datacaster.HashCasters.Base do
  alias Datacaster.{
    Context,
    Success,
    Error
  }

  def build_from_key_casters(key_casters) do
    fn (value, context) ->
      results = Enum.map(key_casters, fn {key_to_check, caster} ->
        {result, _} = caster.(value, context)
        {key_to_check, result}
      end)

      failures = Enum.filter(results, fn {_key, result} ->
        case result do
          %Success{} ->
            false
          _ ->
            true
        end
      end)

      if length(failures) == 0 do
        result = Enum.reduce(results, %{}, fn {key, result}, acc ->
          %Success{value: value} = result
          Map.put(acc, key, value)
        end)

        keys_checked = results |> Enum.map(fn {key, _} -> key end)

        {
          Map.merge(value, result) |> clear_absent_keys |> Success.new,
          Context.check_key(context, keys_checked)
        }
      else
        result = Enum.reduce(failures, %Error.Map{}, fn {key, result}, acc ->
          Error.Map.add_key(acc, key, result)
        end)

        {result, context}
      end
    end
  end

  defp clear_absent_keys(result) do
    Map.filter(result, fn {_key, value} ->
      value != Datacaster.Absent
    end)
  end
end
