defmodule Datacaster.Contract do
  defmacro __using__(_) do
    quote do
      import Datacaster.Contract

      @__datacaster__casters_to_compile []

      @before_compile Datacaster.Contract

      def validate(name, input, context \\ %{}) do
        Datacaster.Executor.validate(get_schema(name), input, context)
      end

      def validate_to_changeset(name, input, context \\ %{}) do
        Datacaster.Executor.validate_to_changeset(get_schema(name), input, context)
      end

      defp get_schema(name) do
        Kernel.apply(__MODULE__, :"__datacaster_#{name}__", [])
      end
    end
  end

  defmacro define_schema(name, do: body) do
    function_get_name = :"__datacaster_#{name}__"
    function_compile_name = :"__datacaster_#{name}_compile__"

    module = __CALLER__.module

    caster_key = :"#{module}_#{name}"

    quote do
      use Datacaster
  
      @__datacaster__casters_to_compile [unquote(name) | @__datacaster__casters_to_compile]

      def unquote(function_get_name)() do
        Application.get_env(:datacaster, unquote(caster_key))
      end

      def unquote(function_compile_name)() do
        caster = Datacaster.schema(do: unquote(body))
        Application.put_env(:datacaster, unquote(caster_key), caster)
      end
    end
  end

  defmacro define_partial_schema(name, do: body) do
    function_get_name = :"__datacaster_#{name}__"
    function_compile_name = :"__datacaster_#{name}_compile__"

    module = __CALLER__.module

    caster_key = :"#{module}_#{name}"

    quote do
      use Datacaster
  
      @__datacaster__casters_to_compile [unquote(name) | @__datacaster__casters_to_compile]

      def unquote(function_get_name)() do
        Application.get_env(:datacaster, unquote(caster_key))
      end

      def unquote(function_compile_name)() do
        caster = Datacaster.partial_schema(do: unquote(body))
        Application.put_env(:datacaster, unquote(caster_key), caster)
      end
    end
  end

  defmacro define_choosy_schema(name, do: body) do
    function_get_name = :"__datacaster_#{name}__"
    function_compile_name = :"__datacaster_#{name}_compile__"

    module = __CALLER__.module

    caster_key = :"#{module}_#{name}"

    quote do
      use Datacaster
  
      @__datacaster__casters_to_compile [unquote(name) | @__datacaster__casters_to_compile]

      def unquote(function_get_name)() do
        Application.get_env(:datacaster, unquote(caster_key))
      end

      def unquote(function_compile_name)() do
        caster = Datacaster.choosy_schema(do: unquote(body))
        Application.put_env(:datacaster, unquote(caster_key), caster)
      end
    end
  end

  defmacro __before_compile__(_) do
    quote do
      def __datacaster_compile_schemas__() do
        Enum.each(@__datacaster__casters_to_compile, fn name ->
          Kernel.apply(__MODULE__, :"__datacaster_#{name}_compile__", [])
        end)
      end
    end
  end
end
