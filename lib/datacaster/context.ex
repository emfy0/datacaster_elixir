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
      gettext_namespace: gettext_default_namespace(),
      gettext_context: nil,
      gettext_options: %{}
    }
  end

  defmodule CasterHelpers do
    defmacro __using__(_) do
      quote do
        import unquote(__MODULE__)
      end
    end

    defmacro gettext_opts!(opts) do
      opts = Enum.into(opts, %{})

      quote do
        old_opts = var!(context).__datacaster__.gettext_options
        new_opts = Map.merge(old_opts, unquote(Macro.escape(opts)))
        var!(context) = put_in(var!(context).__datacaster__.gettext_options, new_opts)
      end
    end
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

  defp gettext_default_namespace, do:
    Application.get_env(:datacaster, :gettext_default_namespace)
end
