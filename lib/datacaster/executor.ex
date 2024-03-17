defmodule Datacaster.Executor do
  alias Datacaster.Error
  alias Datacaster.Success

  def run(caster, value, context \\ %{}) do
    value = if is_map(value), do: stringify_keys(value), else: value

    context = Map.merge(context, %{__datacaster__: Datacaster.Context.new})
    {result, _context} = caster.(value, context)
    result
  end

  def validate(caster, value, context \\ %{}) do
    case run(caster, value, context) do
      %Success{value: value} -> {:ok, value}
      error -> {:error, localize_error(error)}
    end
  end

  defp localize_error(error) do
    case error do
      %Error{error: error, context: context} ->
        localize_error_message(error, context)
      %Error.List{errors: errors} ->
        errors
        |> Enum.map(&localize_error/1)
      %Error.Map{errors: errors} ->
        errors
        |> Enum.map(fn {key, error} -> {key, localize_error(error)} end)
        |> Enum.into(%{})
    end
  end

  defp localize_error_message(message, context) do
    context = context.__datacaster__

    gettext_namespace = context.gettext_namespace
    gettext_options = Map.put_new(context.gettext_options, :value, inspect(context.error_value))
    gettext_context = context.gettext_context

    if gettext_options[:count] do
      gettext_module().dpngettext(
        gettext_backend(),
        gettext_namespace,
        gettext_context,
        message,
        message,
        gettext_options[:count],
        gettext_options
      )
    else
      gettext_module().dpgettext(
        gettext_backend(),
        gettext_namespace,
        gettext_context,
        message,
        gettext_options
      )
    end
  end

  def stringify_keys(map) when is_map(map) do
    map
    |> Enum.map(fn {k, v} -> {stringify_key(k), stringify_keys(v)} end)
    |> Enum.into(%{})
  end

  def stringify_keys(val), do: val

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)
  defp stringify_key(key), do: key

  defp gettext_backend, do:
    Application.get_env(:datacaster, :gettext_default_backend)

  defp gettext_module, do:
    Application.get_env(:datacaster, :gettext_module)
end
