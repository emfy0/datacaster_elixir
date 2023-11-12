defmodule Datacaster.Predefined do
  alias Datacaster.{Success, Error}

  defmacro cast(func) do
    build_caster(func)
  end

  defp build_caster(func) do
    quote do
      %Datacaster.Caster{
        caster: unquote(build_function(func)),
        kind: :caster
      }
    end
  end

  defmacro check(error_msg \\ "invalid", func) do
    build_checker(error_msg, func)
  end

  defp build_checker(error_msg, func) do
    func = build_function(func)

    check_func = quote bind_quoted: [func: func, error_msg: error_msg] do
      fn (input_value, context) ->
        {value, context} = func.(input_value, context)

        if value do
          Success.new(input_value, context)
        else
          Error.new(error_msg, context)
        end
      end
    end

    quote do
      %Datacaster.Caster{
        caster: unquote(check_func),
        kind: :checker
      }
    end
  end

  defp build_function({op = :fn, fn_meta, fn_args}) do
    context_var = {:context, [], nil}

    fn_args = Enum.map(fn_args, fn ({:->, meta, [args, body]}) ->
      {
        :->,
        meta,
        [
          args ++ [context_var],
          quote do
            result = unquote(body)
            {result, unquote(context_var)}
          end
        ]
      }
    end)

    {op, fn_meta, fn_args}
  end

  defp build_function({_op = :&, _meta, _args} = func) do
    quote bind_quoted: [func: func] do
      case :erlang.fun_info(func)[:arity] do
        1 ->
          fn (value, context) -> {func.(value), context} end
        2 ->
          fn (value, context) -> {func.(value, context), context} end
      end
    end
  end
end
