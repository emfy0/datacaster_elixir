defmodule Datacaster.Casters.AndNode do
  @keys [:left, :right]

  @enforce_keys @keys
  defstruct @keys

  def to_function_definition(
    %__MODULE__{left: left, right: right}, name, caller
  ) do
    left = left.name
    right = right.name

    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(input, context) do
        {result, context} = unquote(left)(input, context)

        case result do
          %Datacaster.Result.Ok{} ->
            unquote(right)(result.value, context)
          %Datacaster.Result.Error{} ->
            {result, context}
        end
      end
    end
  end
end
