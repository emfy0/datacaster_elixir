defmodule Datacaster.Contract do
  defmacro __using__(_) do
    quote do
      require unquote(__MODULE__)
      import unquote(__MODULE__)
    end
  end

  defmacro schema(do: block) do
    quote do
      fn ->
        import Kernel, except: [>: 2, <>: 2, *: 2]
        use Datacaster.Predefined

        unquote(block)
      end.()
    end
  end
end
