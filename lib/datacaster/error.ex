defmodule Datacaster.Error do
  defstruct error: nil

  def new(value = %Datacaster.Success{}) do
    value
  end

  def new(value = %__MODULE__{}) do
    value
  end

  def new(error) do
    %__MODULE__{error: error}
  end
end
