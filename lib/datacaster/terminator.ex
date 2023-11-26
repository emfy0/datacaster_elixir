defmodule Datacaster.Terminator do
  defmacro __using__(_) do
    quote do
      alias Datacaster.{
        Success,
        Error,
      }

      def build(caster) do
        fn (value, context) -> {result, context} = caster.(value, context)

          case result do
            %Success{} ->
              process_schema(value, context, result)
            %Error{} ->
              {result, context}
            %Error.Map{} ->
              {result, context}
            %Error.List{} ->
              {result, context}
          end
        end
      end

      defp process_schema(value, context, result) do
        current_checked_schema = context.__datacaster__.checked_schema

        if need_to_check_schema?(current_checked_schema) do
          check_schema(value, context, result, current_checked_schema)
        else
          {result, context}
        end
      end

      defp need_to_check_schema?(checked_schema) do
        length(checked_schema) > 0
      end

      defp retrive_schema_from_value(value) when is_map(value) do
        Map.keys(value) |> Enum.map(&normalize_atoms/1)
      end

      defp retrive_schema_from_value(value) do
        cond do
          Keyword.keyword?(value) ->
            Keyword.keys(value) |> Enum.map(&normalize_atoms/1)
          true ->
            nil
        end
      end

      defp normalize_atoms(value) when is_atom(value), do: Atom.to_string(value)
      defp normalize_atoms(value), do: value
    end
  end
end
