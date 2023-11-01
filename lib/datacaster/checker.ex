defmodule Datacaster.Checker do
  alias Datacaster.Base
  import Base

  def check(error_key \\ nil, func) do
    to_checker from_function(error_key, func)
  end
  
  defp to_checker(%Base{error_key: error_key, func: func}) do
    func = fn (input, context) ->
      result = func.(input, context)

      case result do
        {:error} ->
          {:error}
        {:__datacaster__, meta} ->
          {:__datacaster__, meta}  
        val ->
          if val, do: {:ok, val}, else: {:error}
      end
    end

    %Base{error_key: error_key, func: func}
  end
end
