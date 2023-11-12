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

  defmodule Success do
    defstruct value: nil

    def new(value) do
      %__MODULE__{value: value}
    end
  end

  defmodule Error do
    defstruct error: nil

    def new(error) do
      %__MODULE__{error: error}
    end
  end
end

# !@#$%^&*()_+{}|:"<>?~`-=[]\;',./
