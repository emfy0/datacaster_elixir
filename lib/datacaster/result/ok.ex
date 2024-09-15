defmodule Datacaster.Result.Ok do
  defstruct value: nil, ok?: true, error?: false

  def new(value = %Datacaster.Result.Error{}) do
    value
  end

  def new(value = %__MODULE__{}) do
    value
  end

  def new(value) do
    %__MODULE__{value: value}
  end
end
