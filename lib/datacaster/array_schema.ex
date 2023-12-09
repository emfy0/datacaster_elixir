defmodule Datacaster.ArraySchema do
  alias Datacaster.{
    Success,
    Error,
  }

  def build(caster) do
    fn (value, context) ->
      results =
        value
        |> Enum.with_index()
        |> Enum.map(fn {value, index} ->
          {index, caster.(value, context)}
        end)

      failures = Enum.filter(results, fn {_index, {result, _context}} ->
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
        results = Enum.map(results, fn {_index, {result, _context}} ->
          %Success{value: value} = result
          value
        end)

        {
          results |> Success.new,
          context
        }
      else
        result = Enum.reduce(failures, %Error.Map{}, fn {index, {result, _context}}, acc ->
          Error.Map.add_key(acc, index, result)
        end)

        {result, context}
      end
    end
  end
end
