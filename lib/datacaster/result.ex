defmodule Datacaster.Result do
  alias Datacaster.Result.{Ok, Error}

  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
      alias Datacaster.Result.{Ok, Error}
    end
  end

  defdelegate ok(v), to: Ok, as: :new
  defdelegate error(v), to: Error, as: :new

  def bind(%Ok{value: value}, callable), do: callable.(value)
  def bind(%Error{} = failure, _callable), do: failure

  def fmap(result, callable), do: ok(bind(result, callable))

  def value_or(%Error{} = failure, val) when is_function(val), do: error(val.(failure.error))
  def value_or(%Error{} = _failure, val), do: val
  def value_or(%Ok{} = result, _val), do: result
end
