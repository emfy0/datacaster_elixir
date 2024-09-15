defmodule Datacaster.Casters.Caster do
  @keys [:lambda]

  @enforce_keys @keys
  defstruct @keys

  alias Datacaster.Result.{Ok, Error}
  import Datacaster.Casters.FunctionBuilder
  alias Datacaster.Context

  def to_function_definition(
    %__MODULE__{lambda: lambda}, name, caller
  ) do
    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(var!(input), var!(context)) do
        {result, context} = unquote(lambda_to_func(lambda)).(var!(input), var!(context))

        case result do
          %Ok{} ->
            {result, context}
          %Error{} ->
            {
              %Error{result | context: Context.put_error(context, var!(input))},
              var!(context)
            }
          _ ->
            raise "invalid caster return value, expected " <>
              "%Datacaster.Result.Ok{} or %Datacaster.Result.Error{}, got: #{inspect(result)}"
        end
      end
    end
  end
end
