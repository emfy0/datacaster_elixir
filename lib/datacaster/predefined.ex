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

  def hash, do: check("should be a hash", &is_map/1)
  def array, do: check("should be an array", &is_list/1)
  def string, do: check("should be a string", &is_bitstring/1)
  def integer, do: check("should be an integer", &is_integer/1)
  def float, do: check("should be a float", &is_float/1)
  def boolean, do: check("should be a boolean", &is_boolean/1)

  def pick(opts) do
    Picker.build(opts)
  end

  def pass do
    fn (value, context) -> {value, context} end
  end

  def compare(value) do
    check("should be equal to #{inspect(value)}", &(&1 == value))
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
