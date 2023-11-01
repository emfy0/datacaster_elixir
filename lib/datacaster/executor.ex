defmodule Datacaster.Executor do
  alias Datacaster.Base

  def process(%Base{error_key: error_key, func: func}, input, context) do
    case func.(input, context) do
      {:ok, result} ->
        {:ok, result}
      {:error} ->
        build_error_message(error_key, %{value: input})
      {:__datacaster__, meta} ->
        retrive_result_from_meta(meta, input, error_key)
    end
  end

  defp retrive_result_from_meta(meta, input, error_key) do
    case meta do
      %{gettext: gettext_vars} ->
        build_error_message(error_key, Map.merge(gettext_vars, %{value: input}))
    end
  end

  defp build_error_message(error_key, gettext_vars) do
    {:error, error_key, gettext_vars}
  end
end
