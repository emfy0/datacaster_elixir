defmodule Datacaster.Casters.Switch do
  alias Datacaster.Casters.Picker

  @keys [:statement, :on_clauses, :else_statement]

  @enforce_keys @keys
  defstruct @keys

  def to_function_definition(
    %__MODULE__{statement: statement, on_clauses: on_clauses, else_statement: else_statement}, name, caller
  ) do
    on_clauses =
      on_clauses
      |> Enum.map(fn {key, caster_definition} -> {key, caster_definition.name} end)

    else_statement = else_statement && else_statement.name

    quote generated: true, file: caller.file, line: caller.line do
      def unquote(name)(input, context) do
        {statement_result, statement_context} =
          case unquote(Macro.escape(statement)) do
            statement when is_struct(statement) ->
              Kernel.apply(__MODULE__, statement.name, [input, context])
            statement ->
              Picker.pick(statement, input, context)
          end

        if statement_result.ok? do
          value = statement_result.value

          result =
            # TODO сюда приходят полные дефиниции, вероятно их надо бы срезать для производительности, потому что они наверно все остаются в результирующем коде аналогично и для остальных мест
            Enum.reduce_while(unquote(Macro.escape(on_clauses)), nil, fn {on_clause, action}, _ ->
              {on_result, on_context} =
                case on_clause do
                  on_clause when is_struct(on_clause) ->
                    Kernel.apply(__MODULE__, on_clause.name, [value, statement_context])
                  on_clause ->
                    equals =
                      case on_clause do
                        on_clause when is_atom(on_clause) ->
                          on_clause == value || Atom.to_string(on_clause) == value
                        on_clause ->
                          on_clause == value
                      end

                    if equals do
                      {Datacaster.Result.ok(value), statement_context}
                    else
                      {Datacaster.Result.Error.new("is invalid"), statement_context}
                    end
                end

              if on_result.ok? do
                {:halt, Kernel.apply(__MODULE__, action, [input, on_context])}
              else
                {:cont, nil}
              end
            end)

          if result do
            result
          else
            else_statement = unquote(Macro.escape(else_statement))

            case else_statement do
              else_statement when is_struct(else_statement) ->
                Kernel.apply(__MODULE__, else_statement.name, [statement_result, statement_context])
              nil ->
                {
                  Datacaster.Result.Error.new("is invalid", Datacaster.Context.put_error(statement_context, input)),
                  statement_context
                }
            end
          end
        else
          {statement_result, statement_context}
        end
      end
    end
  end
end
