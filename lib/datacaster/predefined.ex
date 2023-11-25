defmodule Datacaster.Predefined do
  alias Datacaster.{
    Success,
    Error,
    Caster,
    Checker,
    Picker,
    HashSchema,
    Terminator
  }

  def left > right when is_function(left) and is_function(right) do
    fn (value, context) ->
      {result, context} = left.(value, context)

      case result do
        %Success{value: value} ->
          right.(value, context)
        %Error{} ->
          {result, context}
      end
    end
  end
  defdelegate left > right, to: Kernel

  def left <> right when is_function(left) and is_function(right) do
    fn (value, context) ->
      {result, context} = left.(value, context)

      case result do
        %Error{}->
          right.(value, context)
        %Success{} ->
          {result, context}
      end
    end
  end
  defdelegate left <> right, to: Kernel

  def left * right when is_function(left) and is_function(right) do
    fn (value, context) ->
      {left_result, context} = left.(value, context)

      case left_result do
        %Success{value: value} ->
          right.(value, context)
        %Error{} ->
          {right_result, context} = right.(value, context)

          case right_result do
            %Success{} ->
              {left_result, context}
            %Error{} ->
              {
                Error.merge(left_result, right_result), context
              }
          end
      end
    end
  end
  defdelegate left * right, to: Kernel

  defmacro cast(func) do
    Caster.build(func)
  end

  defmacro check(error_msg \\ "invalid", func) do
    Checker.build(error_msg, func)
  end

  def pick(opts) do
    Picker.build(opts)
  end

  def hash_schema(opts) do
    HashSchema.build(opts)
  end

  def schema(caster) do
    Terminator.build(caster)
  end
end
