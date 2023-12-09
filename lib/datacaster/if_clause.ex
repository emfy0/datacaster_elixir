defmodule Datacaster.IfClause do
  alias Datacaster.{
    Success,
  }

  def build(condition, then_action, else_action) do
    fn (value, context) ->
      {result, _context} = condition.(value, context)

      case result do
        %Success{} ->
          then_action.(value, context)
        _ ->
          else_action.(value, context)
      end
    end
  end
end
