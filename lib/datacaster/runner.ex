defmodule Datacaster.Runner do
  import Datacaster.Builder

  alias Datacaster.{Success}

  def build(func) do
    func = build_function(func)

    check_func = quote bind_quoted: [func: func] do
      fn (input_value, context) ->
        {_, res_context} = func.(input_value, context)

        {Success.new(input_value), res_context}
      end
    end

    quote do
      unquote(check_func)
    end
  end
end

