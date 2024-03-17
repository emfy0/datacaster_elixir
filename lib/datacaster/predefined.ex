defmodule Datacaster.Predefined do
  alias Datacaster.{
    Success,
    Error,
    Caster,
    Checker,
    Picker,
    ArraySchema,
    HashCasters.HashSchema,
    HashCasters.HashMapper,
    Terminator.Raiser,
    Terminator.Sweeper,
    IfClause,
    SwithClause
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
        _ ->
          {result, context}
      end
    end
  end
  defdelegate left > right, to: Kernel

  def left <> right when is_function(left) and is_function(right) do
    fn (value, context) ->
      {result, left_context} = left.(value, context)

      case result do
        %Success{} ->
          {result, left_context}
        _ ->
          right.(value, context)
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
        _ ->
          {right_result, context} = right.(value, context)

          case right_result do
            %Success{} ->
              {left_result, context}
            _ ->
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

  def hash(error \\ nil) do 
    error = error || "should be a hash"
    check(error, &is_map/1)
  end

  def array(error \\ nil) do
    error = error || "should be an array"
    check(error, &is_list/1)
  end

  def string(error \\ nil) do
    error = error || "should be a string"
    check(error, &is_bitstring/1)
  end

  def integer(error \\ nil) do
    error = error || "should be an integer"
    check(error, &is_integer/1)
  end

  def float(error \\ nil) do
    error = error || "should be a float"
    check(error, &is_float/1)
  end

  def boolean(error \\ nil) do
    error = error || "should be a boolean"
    check(error, &is_boolean/1)
  end

  def pick(opts) do
    Picker.build(opts)
  end

  def included_in(list, error \\ nil) do
    error = error || "should be included in #{inspect(list)}"
    check(error, &Enum.member?(list, &1))
  end

  def pass do
    fn (value, context) -> {value, context} end
  end

  def compare(value, error \\ nil) do
    error = error || "should be equal to #{inspect(value)}"
    check(error, &(&1 == value))
  end

  def hash_schema(opts) do
    __MODULE__.>(hash(), HashSchema.build(opts))
  end

  def transform_to_hash(opts) do
    HashMapper.build(opts)
  end

  def array_of(caster) do
    __MODULE__.>(array(), ArraySchema.build(caster))
  end

  def on(caster, opts) do
    IfClause.build(caster, opts[:then], opts[:else])
  end

  def switch(condition, opts) do
    SwithClause.build(condition, opts[:on], opts[:else])
  end
end
