defmodule Datacaster.Executor do
  def run(caster, value, context \\ %{}) do
    context = Map.merge(context, %{__datacaster__: Datacaster.Context.new})
    {result, _context} = caster.(value, context)
    result
  end
end
