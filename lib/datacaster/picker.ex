defmodule Datacaster.Picker do
  alias Datacaster.{Error, Success, Absent}

  def build(opts) do
    %Datacaster.Node{
      caster: build_function(opts),
      kind: :picker
    }
  end

  defp build_function(opts) when is_list(opts) do
    fn (value, context) ->
      result = Enum.reduce(opts, [], fn (opt, acc) ->
        new_value = flat_visitor(opt).(value)
        acc ++ [new_value]
      end)

      {Success.new(result), context}
    end
  end

  defp build_function(opts) when is_tuple(opts) do
    opts = Tuple.to_list(opts)

    fn (value, context) ->
      result = Enum.reduce(opts, value, fn (opt, acc) ->
        cond do
          acc == Absent ->
            acc
          true ->
            flat_visitor(opt).(acc)
        end
      end)

      {Success.new(result), context}
    end
  end

  defp build_function(opt) do
    fn (value, context) ->
      case flat_visitor(opt).(value) do
        %Error{} = error ->
          {error, context}
        value ->
          {Success.new(value), context}
      end
    end
  end

  defp flat_visitor(opt) when is_integer(opt) do
    fn (value) ->
      cond do
        is_map(value) -> 
          Map.get(value, opt, Absent)
        is_list(value) ->
          Enum.at(value, opt, Absent)
        is_tuple(value) and opt >= 0 ->
          if opt < tuple_size(value) do
            elem(value, opt)
          else
            Absent
          end
        true ->
          Error.new("is not a collection")
      end
    end
  end

  defp flat_visitor(opt) do
    fn (value) ->
      cond do
        is_map(value) -> 
          Map.get(value, opt, Absent)
        Keyword.keyword?(value) ->
          Keyword.get(value, opt, Absent)
        true ->
          Error.new("is not a hash")
      end
    end
  end
end
