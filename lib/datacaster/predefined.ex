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
    Transformer,
    Trier,
    Runner,
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

  defmacro check(error \\ "invalid", func) do
    Checker.build(error, func)
  end

  defmacro transform(func) do
    Transformer.build(func)
  end

  defmacro run(func) do
    Runner.build(func)
  end

  defmacro trier(error \\ "invalid", exception, func) do
    Trier.build(func, exception, error)
  end

  def gettext_opts(caster, opts) do
    __MODULE__.>(run(fn _ -> gettext_opts!(opts) end), caster)
  end

  def gettext_namespace(caster, namespaces) do
    __MODULE__.>(run(fn _ -> gettext_namespace!(namespaces) end), caster)
  end

  def gettext_context(caster, gettext_context) do
    __MODULE__.>(run(fn _ -> gettext_context!(gettext_context) end), caster)
  end

  def remove do
    fn (_, context) -> {Success.new(Datacaster.Absent), context} end
  end

  def hash(error \\ "should be a hash") do 
    check(error, &is_map/1)
  end

  def array(error \\ "should be an array") do
    check(error, &is_list/1)
  end

  def string(error \\ "should be a string") do
    check(error, &is_bitstring/1)
  end

  def non_empty_string(error \\ "should be a non-empty string") do
    check(error, &(&1 != "" && is_bitstring(&1)))
  end

  def integer(error \\ "should be an integer") do
    check(error, &is_integer/1)
  end

  def to_integer(error \\ "should be an integer") do
    trier(error, MatchError, fn value ->
      case value do
        value when is_integer(value) -> value
        value when is_bitstring(value) ->
          {value, _} = Integer.parse(value)
          value
        _ -> Error.new(error)
      end
    end)
  end

  def to_float(error \\ "should be a float") do
    trier(error, MatchError, fn value ->
      case value do
        value when is_float(value) -> value
        value when is_bitstring(value) ->
          {value, _ } = Float.parse(value)
          value
        _ -> Error.new(error)
      end
    end)
  end

  def float(error \\ "should be a float") do
    check(error, &is_float/1)
  end

  def boolean(error \\ "should be a boolean") do
    check(error, &is_boolean/1)
  end

  def to_boolean(error \\ "should be a boolean") do
    cast(fn value ->
      case value do
        true -> Success.new(true)
        false -> Success.new(false)
        "true" -> Success.new(true)
        "false" -> Success.new(false)
        1 -> Success.new(true)
        0 -> Success.new(false)
        "1" -> Success.new(true)
        _ -> Error.new(error)
      end
    end)
  end

  def iso_8601(error \\ "should be an ISO 8601 date") do
    cast(fn date ->
      case DateTime.from_iso8601(date) do
        {:ok, date, _} ->
          Success.new(date)
        _ ->
          Error.new(error)
      end
    end)
  end

  def optional(caster, opts \\ []) do
    if Keyword.has_key?(opts, :on) do
      __MODULE__.<>(
        __MODULE__.>(compare(opts[:on]), remove()), caster
      )
    else
      __MODULE__.<>(compare(Datacaster.Absent), caster)
    end
  end

  def pick(opts) do
    Picker.build(opts)
  end

  def included_in(list, error \\ nil) do
    error = error || "should be included in #{inspect(list)}"
    check(error, &Enum.member?(list, &1))
  end

  def pass do
    fn (value, context) -> {Success.new(value), context} end
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
