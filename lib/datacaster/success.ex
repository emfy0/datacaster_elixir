defmodule Datacaster.Success do
  defstruct value: nil

  def new(value = %Datacaster.Error{}) do
    value
  end

  def new(value = %__MODULE__{}) do
    value
  end

  def new(value) do
    %__MODULE__{value: value}
  end
end
