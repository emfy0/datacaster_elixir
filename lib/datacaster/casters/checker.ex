defmodule Datacaster.Casters.Checker do
  @keys [:lambda, :error_msg]

  @enforce_keys @keys
  defstruct @keys

  import Datacaster.Casters.FunctionBuilder
  alias Datacaster.Context

  def to_function_definition(
    %__MODULE__{lambda: lambda, error_msg: error_msg}, name, caller
  ) do
    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(var!(input), var!(context)) do
        {result, res_context} = unquote(lambda_to_func(lambda)).(var!(input), var!(context))

        if result do
          {Datacaster.Result.Ok.new(var!(input)), res_context}
        else
          {
            Datacaster.Result.Error.new(
              unquote(error_msg), Context.put_error(res_context, var!(input))
            ),
            var!(context)
          }
        end
      end
    end
  end
end
