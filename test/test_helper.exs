ExUnit.start()

defmodule DatacasterTestHelper do
  alias Datacaster.Context

  def checked_context(val, error \\ nil) do
    %{__datacaster__: Context.new}
    |> Context.check_key(val)
    |> Context.put_error(error)
  end
end

