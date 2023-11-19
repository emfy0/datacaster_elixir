defmodule Datacaster.Executor do
  def run(caster, value, context \\ %{}) do
    context = Map.merge(context, %{__datacaster__: Datacaster.Context.new})
    caster.(value, context)
  end
end
