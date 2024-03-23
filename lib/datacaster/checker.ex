defmodule Datacaster.Checker do
  import Datacaster.Builder

  alias Datacaster.{Error, Success, Context}

  def build(error_msg, func) do
    func = build_function(func)

    check_func = quote bind_quoted: [func: func, error_msg: error_msg] do
      fn (input_value, context) ->
        {value, res_context} = func.(input_value, context)

        if value do
          {Success.new(input_value), res_context}
        else
          {Error.new(error_msg, Context.put_error(res_context, input_value)), context}
        end
      end
    end

    quote do
      unquote(check_func)
    end
  end
end
