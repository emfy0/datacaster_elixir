defmodule Datacaster.Casters.Transformer do
  @keys [:lambda]

  @enforce_keys @keys
  defstruct @keys

  import Datacaster.Casters.FunctionBuilder

  def to_function_definition(
    %__MODULE__{lambda: lambda}, name, caller
  ) do
    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(var!(input), var!(context)) do
        {result, res_context} = unquote(lambda_to_func(lambda)).(var!(input), var!(context))

        {Datacaster.Result.Ok.new(result), res_context}
      end
    end
  end
end
