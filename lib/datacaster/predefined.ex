defmodule Datacaster.Predefined do
  alias Datacaster.{
    CasterDefinition,
    Casters
  }

  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)

      Module.register_attribute(__MODULE__, :__datacaster_casters, accumulate: true)
      @before_compile unquote(__MODULE__)
    end
  end

  defmacrop save_caster!(caster) do
    quote do
      caster = unquote(caster)

      quote do
        caster = unquote(caster)
        @__datacaster_casters caster
        caster
      end
    end
  end

  defp _caster(caller, lambda) do
    CasterDefinition.init(Casters.Caster, caller, lambda: lambda)
      |> Macro.escape()
      |> save_caster!()
  end

  defp _check(caller, error_msg, lambda) do
    CasterDefinition.init(Casters.Checker, caller, lambda: lambda, error_msg: error_msg)
      |> Macro.escape()
      |> save_caster!()
  end

  defmacro caster(lambda) do
    CasterDefinition.init(Casters.Caster, __CALLER__, lambda: lambda)
    |> Macro.escape()
    |> save_caster!()
  end

  defmacro check(error_msg \\ "invalid", lambda) do
    CasterDefinition.init(Casters.Checker, __CALLER__, lambda: lambda, error_msg: error_msg)
    |> Macro.escape()
    |> save_caster!()
  end

  defmacro transform(lambda) do
    CasterDefinition.init(Casters.Transformer, __CALLER__, lambda: lambda)
    |> Macro.escape()
    |> save_caster!()
  end

  defmacro left > right do
    caller = __CALLER__

    quote(do: CasterDefinition.init(
      Casters.AndNode, unquote(Macro.escape(caller)), left: unquote(left), right: unquote(right)
    ))
    |> save_caster!()
  end

  defmacro left <> right do
    caller = __CALLER__

    quote(do: CasterDefinition.init(
      Casters.OrNode, unquote(Macro.escape(caller)), left: unquote(left), right: unquote(right)
    ))
    |> save_caster!()
  end

  defmacro to_boolean(error_msg \\ "should be a boolean") do
    lambda = quote do
      fn value ->
        case value do
          x when x in [true, "true", "1"] -> Datacaster.Result.Ok.new(true)
          x when x in [false, "false", "0"] -> Datacaster.Result.Ok.new(false)
          _ -> Datacaster.Result.Error.new(unquote(error_msg))
        end
      end
    end

    _caster(__CALLER__, lambda)
  end

  defmacro uuid(error_msg \\ "should be a uuid") do
    lambda = quote do: &String.match?(&1, ~r/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i)

    _check(__CALLER__, error_msg, lambda)
  end

  defmacro boolean(error_msg \\ "should be a boolean") do
    _check(__CALLER__, error_msg, quote do: &is_boolean/1)
  end

  defmacro float(error_msg \\ "should be a float") do
    _check(__CALLER__, error_msg, quote do: &is_float/1)
  end

  defmacro hash(error_msg \\ "should be a hash") do 
    _check(__CALLER__, error_msg, quote do: &is_map/1)
  end

  defmacro array(error_msg \\ "should be an array") do
    _check(__CALLER__, error_msg, quote do: &is_list/1)
  end

  defmacro string(error_msg \\ "should be a string") do
    _check(__CALLER__, error_msg, quote do: &is_bitstring/1)
  end

  defmacro non_empty_string(error_msg \\ "should be a non-empty string") do
    _check(__CALLER__, error_msg, quote do: &(&1 != "" && is_bitstring(&1)))
  end

  defmacro integer(error_msg \\ "should be an integer") do
    _check(__CALLER__, error_msg, quote do: &is_integer/1)
  end

  defmacro __before_compile__(_) do
    quote do
      Enum.each(@__datacaster_casters, fn caster ->
        Module.eval_quoted(
          __MODULE__, Datacaster.CasterDefinition.to_function_definition(caster)
        )
      end)

      [caster_to_run | _] = @__datacaster_casters
      @__datacaster_caster_name_to_run caster_to_run.name

      def run(input, context) do
        apply(__MODULE__, @__datacaster_caster_name_to_run, [input, context])
      end
    end
  end
end
