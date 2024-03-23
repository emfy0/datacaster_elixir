defmodule Datacaster.Caster do
  import Datacaster.Builder

  alias Datacaster.{Error, Success, Context}

  def build(func) do
    func = build_function(func)

    caster_func = quote bind_quoted: [func: func], generated: true do
      fn (input_value, context) ->
        {value, res_context} = func.(input_value, context)

        case value do
          %Success{} ->
            {value, res_context}
          %Error{} ->
            {%Error{value | context: Context.put_error(res_context, input_value)}, context}
          _ ->
            raise "invalid caster return value, expected Success or Error, got: #{inspect(value)}"
        end
      end
    end

    quote do
      unquote(caster_func)
    end
  end
end
