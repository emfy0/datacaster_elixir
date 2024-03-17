defmodule Datacaster.Context do
  defstruct [
    :checked_schema,
    :error_value,
    :gettext_namespace,
    :gettext_context,
    :gettext_options
  ]

  def new do
    %__MODULE__{
      checked_schema: [],
      error_value: nil,
      gettext_namespace: nil,
      gettext_context: nil,
      gettext_options: []
    }
  end

  def check_key(context, key) when is_list(key) do
    current = context.__datacaster__.checked_schema
    put_in(context.__datacaster__.checked_schema, current ++ key)
  end

  def check_key(context, key) do
    current = context.__datacaster__.checked_schema
    put_in(context.__datacaster__.checked_schema, current ++ [key])
  end

  def put_error(context, value) do
    put_in(context.__datacaster__.error_value, value)
  end
end
