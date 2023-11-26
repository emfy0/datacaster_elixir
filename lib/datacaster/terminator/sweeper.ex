defmodule Datacaster.Terminator.Sweeper do
  use Datacaster.Terminator

  alias Datacaster.{
    Error,
    Success,
  }

  def check_schema(value, context, result, current_checked_schema) do
    case retrive_schema_from_value(value) do
      nil ->
        {result, context}
      schema ->
        diff = schema -- Enum.map(current_checked_schema, &normalize_atoms/1)

        if length(diff) == 0 do
          {result, context}
        else
          %Success{value: value} = result
          {
            Map.drop(value, diff) |> Success.new,
            context
          }
        end
    end
  end
end
