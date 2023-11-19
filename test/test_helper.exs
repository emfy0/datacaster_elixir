ExUnit.start()

defmodule DatacasterTestHelper do
  def call_caster(caster, val, context) do
    caster.(val, context)
  end
end

