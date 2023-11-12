defmodule Datacaster do
  defmacro __using__(_) do
    quote do
      require Datacaster
    end
  end

  defmacro schema(do: block) do
    quote do
      require Datacaster.Predefined
      import Datacaster.Predefined

      unquote(block)
    end
  end

  defmodule Caster do
    defstruct caster: nil, kind: nil
  end

  defmodule Success do
    defstruct value: nil, context: nil

    def new(value, context) do
      %__MODULE__{value: value, context: context}
    end
  end

  defmodule Error do
    defstruct error: nil, context: nil

    def new(error, context) do
      %__MODULE__{error: error, context: context}
    end
  end
end

