defmodule Datacaster.HashCasters.HashMapper do
  import Datacaster.HashCasters.Base

  alias Datacaster.Picker

  def build(opts) do
    Enum.map(opts, fn ({key, caster_node}) ->
      key_to_check = Picker.key_from_pick(key)
      {key_to_check, caster_node}
    end)
    |> build_from_key_casters()
  end
end
