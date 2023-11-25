ExUnit.start()

defmodule DatacasterTestHelper do
  def checked_context(val) do
    %{__datacaster__: %Datacaster.Context{checked_schema: val}}
  end
end

