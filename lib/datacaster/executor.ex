defmodule Datacaster.Executor do
  alias Datacaster.Error
  alias Datacaster.Success

  def run(caster, value, context \\ %{}) do
    context = Map.merge(context, %{__datacaster__: Datacaster.Context.new})
    {result, _context} = caster.(value, context)

    result
  end

  def validate(caster, value, context \\ %{}) do
    value = if is_map(value), do: stringify_keys(value), else: value

    case run(caster, value, context) do
      %Success{value: value} -> {:ok, value}
      error -> {:error, localize_error(error)}
    end
  end

  def validate_to_changeset(caster, value, context \\ %{}) do
    value = if is_map(value), do: stringify_keys(value), else: value

    case validate(caster, value, context) do
      {:ok, value} ->
        {:ok, value}
      {:error, errors} ->
        changeset = errors_to_changeset(value, errors)
        {:error, put_in(changeset.action, :validate)}
    end
  end

  defp localize_error(error) do
    case error do
      %Error{error: error, context: context} ->
        [localize_error_message(error, context)]
      %Error.List{errors: errors} ->
        errors
        |> Enum.flat_map(&localize_error/1)
      %Error.Map{errors: errors} ->
        errors
        |> Enum.map(fn {key, error} -> {key, localize_error(error)} end)
        |> Enum.into(%{})
    end
  end

  def errors_to_changeset(value, errors) when is_map(errors) do
    {top_level_errors, other_errors} = Enum.split_with(errors, fn {_, value} -> is_list(value) end)

    top_level_errors = Enum.map(top_level_errors, fn {key, error} ->
      {String.to_existing_atom(key), errors_to_changeset(value, error)}
    end)

    valid_params_keys = Map.keys(value) -- Map.keys(errors)
    valid_params =
      value
      |> Map.take(valid_params_keys)
      |> Enum.map(fn {key, value} -> {String.to_existing_atom(key), value} end)
      |> Enum.into(%{})

    changes =
      other_errors
      |> Enum.reject(fn {key, _} -> is_list(key) end)
      |> Enum.map(fn {key, error} -> {String.to_existing_atom(key), errors_to_changeset(value[key], error)} end)
      |> Enum.into(%{})
      |> Map.merge(valid_params)

    params = %{
      errors: top_level_errors,
      data: %{},
      changes: changes,
    }
  
    struct(changeset_module(), params) 
  end
  
  def errors_to_changeset(value, error) when is_list(error) do
    error
    |> Enum.map(&errors_to_changeset(value, &1))
  end

  def errors_to_changeset(_, error), do: {error, []}

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

  defp changeset_module, do:
    Application.get_env(:datacaster, :changeset_module)
end
