defmodule Datacaster do
  defmacro __using__(_) do
    quote do
      require Datacaster
    end
  end

  defmacro schema(do: block) do
    quote do
      require Datacaster.Predefined
      import Kernel, except: [>: 2, <>: 2, *: 2]
      import Datacaster.Predefined

      schema(unquote(block))
    end
  end

  defmacro choosy_schema(do: block) do
    quote do
      require Datacaster.Predefined
      import Kernel, except: [>: 2, <>: 2, *: 2]
      import Datacaster.Predefined

      choosy_schema(unquote(block))
    end
  end

  defmacro partial_schema(do: block) do
    quote do
      require Datacaster.Predefined
      import Kernel, except: [>: 2, <>: 2, *: 2]
      import Datacaster.Predefined

      unquote(block)
    end
  end

  defmodule Absent do
  end
end

# !@#$%^&*()_+{}|:"<>?~`-=[]\;',./
