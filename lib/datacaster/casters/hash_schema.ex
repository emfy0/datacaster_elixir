defmodule Datacaster.Casters.HashSchema do
  alias Datacaster.Casters.HashSchema
  alias Datacaster.Casters.Picker

  @keys [:key_and_casters]

  @enforce_keys @keys
  defstruct @keys

  def to_function_definition(
    %__MODULE__{key_and_casters: key_and_casters}, name, caller
  ) do
    keys_and_caster_names =
      key_and_casters
      |> Enum.map(fn {key, caster_definition} -> {key, caster_definition.name} end)

    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(input, context) when is_map(input) and is_non_struct_map(input) do
        keys_and_caster_names = unquote(Macro.escape(keys_and_caster_names))

        {keys_results, context} =
          keys_and_caster_names
          |> Enum.map_reduce(context, fn {key, caster_name}, context ->
            {picker_result, picker_context} = Picker.pick(key, input, context)

            if picker_result.ok? do
              {result, context} = Kernel.apply(__MODULE__, caster_name, [picker_result.value, picker_context])
              {{key, result}, context}
            else
              {{key, picker_result}, picker_context}
            end
          end)

        failures = Enum.filter(keys_results, fn {_key, result} -> result.error? end)

        if length(failures) == 0 do
          result = Enum.reduce(keys_results, %{}, fn {key, result}, acc ->
            Map.put(acc, key, result.value)
          end)

          checked_keys = keys_results |> Enum.map(fn {key, _} -> key end)

          {
            Map.merge(input, result)
            |> HashSchema.clear_absent_keys()
            |> Datacaster.Result.Ok.new(),
            Datacaster.Context.check_key(context, checked_keys)
          }
        else
          result = Enum.reduce(failures, %Datacaster.Result.Error.Map{}, fn {key, result}, acc ->
            Datacaster.Result.Error.Map.add_key(acc, key, result)
          end)

          {result, context}
        end
      end

      def unquote(name)(input, context) do
        {
          Datacaster.Result.Error.new("is not a hash", Datacaster.Context.put_error(context, input)),
          context
        }
      end
    end
  end

  def clear_absent_keys(result) do
    Map.filter(result, fn {_key, value} ->
      value != Datacaster.Absent.instance()
    end)
  end
end
