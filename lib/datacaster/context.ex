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
        import Datacaster.Context
        import unquote(__MODULE__)
      end
    end

    defmacro gettext_opts!(opts) do
      quote do
        var!(context) = put_gettext_options(var!(context), unquote(opts))
      end
    end

    defmacro gettext_namespace!(namespace) do
      quote do
        var!(context) = put_gettext_namespace(var!(context), unquote(namespace))
      end
    end

    defmacro gettext_context!(context) do
      quote do
        var!(context) = put_gettext_context(var!(context), unquote(context))
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

  def put_gettext_namespace(context, namespace) do
    put_in(context.__datacaster__.gettext_namespace, namespace)
  end

  def put_gettext_context(context, gettext_context) do
    put_in(context.__datacaster__.gettext_context, gettext_context)
  end

  def put_gettext_options(context, gettext_options) do
    gettext_options = Enum.into(gettext_options, %{})

    old_opts = context.__datacaster__.gettext_options
    new_opts = Map.merge(old_opts, gettext_options)
    put_in(context.__datacaster__.gettext_options, new_opts)
  end

  defp gettext_default_namespace, do:
    Application.get_env(:datacaster, :gettext_default_namespace)
end
