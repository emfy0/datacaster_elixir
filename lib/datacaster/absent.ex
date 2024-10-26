defmodule Datacaster.Absent do
  defstruct [:_]

  def instance, do: %__MODULE__{}
end
