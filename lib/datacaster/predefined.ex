defmodule Datacaster.Predefined do
  alias Datacaster.{
    Success,
    Error,
    Caster,
    Checker,
    Picker,
    HashSchema,
    Terminator.Raiser,
    Terminator.Sweeper,
  }

  def schema(caster) do
    Raiser.build(caster)
  end

  def choosy_schema(caster) do
    Sweeper.build(caster)
  end

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
  
  def hash, do: check("should be a hash", &is_map/1)
  def array, do: check("should be an array", &is_list/1)
  def string, do: check("should be a string", &is_bitstring/1)
  def integer, do: check("should be an integer", &is_integer/1)
  def float, do: check("should be a float", &is_float/1)
  def boolean, do: check("should be a boolean", &is_boolean/1)

  def pick(opts) do
    Picker.build(opts)
  end

  def hash_schema(opts) do
    __MODULE__.>(hash(), HashSchema.build(opts))
  end
end
