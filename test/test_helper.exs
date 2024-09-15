ExUnit.start()

defmodule DatacasterTest do
  defmacro __using__(_) do
    quote do
      use ExUnit.Case
      use Datacaster.Result
      require unquote(__MODULE__)
      import unquote(__MODULE__)

      ExUnit.Case.register_describe_attribute(__MODULE__, :caster)
    end
  end

  defmacro define_caster(do: block) do
    testcaster_name = :"TestCaster#{System.unique_integer([:positive])}"

    quote do
      @caster unquote(testcaster_name)

      defmodule unquote(testcaster_name) do
        use Datacaster.Contract

        schema do
          unquote(block)
        end
      end
    end
  end

  defmacro test_caster(message, do: block) do
    quote do
      test unquote(message), var!(context) do
        unquote(block)
      end
    end
  end

  defmacro run_caster(input, return_context \\ false) do
    quote do
      result = var!(context).registered.caster.run(unquote(input), %{ __datacaster__: Datacaster.Context.new })

      if unquote(return_context) do
        result
      else
        {val, context} = result

        case val do
          %Datacaster.Result.Error{} ->
            %Datacaster.Result.Error{ val | context: nil }
          _ ->
            val
        end
      end
    end
  end
end

# defmodule DatacasterTestHelper do
#   alias Datacaster.Executor
#   alias Datacaster.Context
#
#   def checked_context(val, error \\ nil) do
#     %{__datacaster__: Context.new}
#     |> Context.check_key(val)
#     |> Context.put_error(error)
#   end
#
#   def run_caster(caster, value, context \\ %{}) do
#     value = if is_map(value), do: Executor.stringify_keys(value), else: value
#     Executor.run(caster, value, context)
#   end
# end
#
# defmodule Datacaster.Gettext do
#   use Gettext, otp_app: :datacaster
# end
