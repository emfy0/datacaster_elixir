defmodule Datacaster.Caster do
  import Datacaster.Base

  def cast(error_key \\ nil, func) do
    from_function(error_key, func)
  end
end
