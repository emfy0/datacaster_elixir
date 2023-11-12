defmodule Datacaster.Predefined do
  alias Datacaster.{
    Caster,
    Checker,
    Node,
    Success,
    Error,
    Picker
  }

  defmacro cast(func) do
    Caster.build(func)
  end

  defmacro check(error_msg \\ "invalid", func) do
    Checker.build(error_msg, func)
  end

  def pick(opts) do
    Picker.build(opts)
  end

  def (%Node{} = left) > (%Node{} = right) do
    and_function = fn (value, context) ->
      {result, context} = left.caster.(value, context)

      case result do
        %Success{value: value} ->
          right.caster.(value, context)
        %Error{} ->
          {result, context}
      end
    end

    %Node{
      caster: and_function,
      kind: :and
    }
  end
  defdelegate left > right, to: Kernel

  def (%Node{} = left) <> (%Node{} = right) do
    or_function = fn (value, context) ->
      {result, context} = left.caster.(value, context)

      case result do
        %Error{}->
          right.caster.(value, context)
         %Success{} ->
          {result, context}
      end
    end

    %Node{
      caster: or_function,
      kind: :or
    }
  end
  defdelegate left <> right, to: Kernel
end
