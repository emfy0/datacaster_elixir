defmodule Datacaster.Trier do
  import Datacaster.Builder

  alias Datacaster.{Error, Success, Context}

  def build(func, exception, error_msg) do
    func = build_function(func)

    check_func = quote bind_quoted: [func: func, error_msg: error_msg, exception: exception] do
      fn (input_value, context) ->
        try do
          {value, res_context} = func.(input_value, context)

          {Success.new(value), res_context}
        rescue
          exception -> {Error.new(error_msg, Context.put_error(context, input_value)), context}
        end
      end
    end

    quote do
      unquote(check_func)
    end
  end
end

