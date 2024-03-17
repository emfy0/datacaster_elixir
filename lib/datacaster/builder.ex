defmodule Datacaster.Builder do
  alias Datacaster.Context

  def build_function({op = :fn, fn_meta, fn_args}) do
    context_var = {:context, [generated: true], nil}
    input_var = {:input, [generated: true], nil}

    fn_args = Enum.map(fn_args, fn ({:->, meta, [args, body]}) ->
      args = case length(args) do
        0 ->
          [input_var, context_var]
        1 ->
          args ++ [context_var]
        2 ->
          args
        _ ->
          raise "invalid function argument list: #{inspect(args)}"
      end

      {
        :->,
        meta,
        [
          args,
          quote do
            use Context.CasterHelpers

            result = unquote(body)
            {result, unquote(context_var)}
          end
        ]
      }
    end)

    {op, fn_meta, fn_args}
  end

  def build_function({_op = :&, _meta, _args} = func) do
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
