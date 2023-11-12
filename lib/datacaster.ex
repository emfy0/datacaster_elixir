defmodule Datacaster do
  defmacro __using__(_) do
    quote do
      require Datacaster
    end
  end

  defmacro schema(do: block) do
    quote do
      require Datacaster.Predefined
      import Kernel, except: [>: 2, <>: 2]
      import Datacaster.Predefined

      unquote(block)
    end
  end

  defmodule Node do
    defstruct caster: nil, kind: nil
  end

  defmodule Absent do
  end
end

# !@#$%^&*()_+{}|:"<>?~`-=[]\;',./
