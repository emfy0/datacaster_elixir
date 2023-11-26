defmodule Datacaster.Terminator.Raiser do
  use Datacaster.Terminator

  alias Datacaster.Error

  def check_schema(value, context, result, current_checked_schema) do
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
end

