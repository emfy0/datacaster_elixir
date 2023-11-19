defmodule Datacaster.Context do
  defstruct [:checked_schema]

  def new do
    %__MODULE__{
      checked_schema: [],
    }
  end

  def check_key(context, key) when is_list(key) do
    current = context.__datacaster__.checked_schema
    put_in(context.__datacaster__.checked_schema, current ++ key)
  end
end
