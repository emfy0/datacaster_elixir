defmodule Datacaster.HashCasters.HashSchema do
  import Datacaster.HashCasters.Base

  alias Datacaster.{
    Picker,
    Predefined,
  }

  def build(opts) do
    Enum.map(opts, fn ({key, caster_node}) ->
      picker = Picker.build(key)
      node_with_picker = Predefined.>(picker, caster_node)
      key_to_check = Picker.key_from_pick(key)

      {
        key_to_check,
        fn (value, context) ->
          node_with_picker.(value, context)
        end
      }
    end)
    |> build_from_key_casters()
  end
end
