defmodule Datacaster.Checker do
  import Datacaster.Builder

  alias Datacaster.{Error, Success}

  def build(error_msg, func) do
    func = build_function(func)

    check_func = quote bind_quoted: [func: func, error_msg: error_msg] do
      fn (input_value, context) ->
        {value, res_context} = func.(input_value, context)

        if value do
          {Success.new(input_value), context}
        else
          {Error.new(error_msg, res_context), context}
        end
      end
    end

    quote do
      unquote(check_func)
    end
  end
end
