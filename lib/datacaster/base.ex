defmodule Datacaster.Base do
  defstruct error_key: nil, func: nil

  def from_function(error_key, func) do
    func =
      case :erlang.fun_info(func)[:arity] do
        1 ->
          fn (input, _context) -> func.(input) end
        2 ->
          func
        arity ->
          raise "Invalid arity for function, expected 1 or 2, got #{arity}"
      end

    %__MODULE__{error_key: error_key, func: func}
  end
end
