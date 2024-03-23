ExUnit.start()

defmodule DatacasterTestHelper do
  alias Datacaster.Executor
  alias Datacaster.Context

  def checked_context(val, error \\ nil) do
    %{__datacaster__: Context.new}
    |> Context.check_key(val)
    |> Context.put_error(error)
  end

  def run_caster(caster, value, context \\ %{}) do
    value = if is_map(value), do: Executor.stringify_keys(value), else: value
    Executor.run(caster, value, context)
  end
end

defmodule Datacaster.Gettext do
  use Gettext, otp_app: :datacaster
end
