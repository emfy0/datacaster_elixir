defmodule Datacaster.Caster do
  import Datacaster.Builder

  alias Datacaster.{Error, Success}

  def build(func) do
    func = build_function(func)

    caster_func = quote bind_quoted: [func: func], generated: true do
      fn (input_value, context) ->
        {value, context} = func.(input_value, context)

        case value do
          %Success{} ->
            {value, context}
          %Error{} ->
            {value, context}
          _ ->
            raise "invalid caster return value, expected Success or Error, got: #{inspect(value)}"
        end
      end
    end

    quote do
      %Datacaster.Node{
        caster: unquote(caster_func),
        kind: :caster
      }
    end
  end
end
