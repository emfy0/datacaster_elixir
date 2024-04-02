defmodule Datacaster.Transaction.Exception do
  defexception [:data, :message]

  def exception(data) do
    %__MODULE__{data: data, message: "Transaction failed"}
  end
end
