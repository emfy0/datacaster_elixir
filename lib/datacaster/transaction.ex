defmodule Datacaster.Transaction do
  defmacro __using__(_) do
    quote do
      @steps []

      import unquote(__MODULE__)
      require unquote(__MODULE__)

      @before_compile unquote(__MODULE__)
    end
  end

  defmodule Modifier do
    def modify(name, :with, opts, block) do
      quote do
        unquote(block)
        defdelegate unquote(name)(params), to: unquote(opts), as: :run
        defoverridable [{unquote(name), 1}]
      end
    end

    def modify(_, _, _, block), do: block
  end

  defmodule Finalizers do
    def finalizer(:map, name, _opts) do
      quote do
        defoverridable [{unquote(name), 1}]
        def unquote(name)(params) do
          {:ok, super(params)}
        end
      end
    end

    def finalizer(:tee, name, _opts) do
      quote do
        defoverridable [{unquote(name), 1}]
        def unquote(name)(params) do
          super(params)
          {:ok, params}
        end
      end
    end

    def finalizer(_, _, _opts), do: nil
  end

  defmacro step(name, opts \\ []) do
    block = build_step(name, opts)

    quote do
      unquote(block)
      @steps @steps ++ [{:step, unquote(name)}]
    end
  end

  defmacro map(name, opts \\ []) do
    block = build_step(name, opts)

    quote do
      unquote(block)
      @steps @steps ++ [{:map, unquote(name)}]
    end
  end

  defmacro tee(name, opts \\ []) do
    block = build_step(name, opts)

    quote do
      unquote(block)
      @steps @steps ++ [{:tee, unquote(name)}]
    end
  end

  defmacro within(adapter_module, adapter_function, do: block) do
    name = String.to_atom("Within#{System.unique_integer()}")

    current_module = __CALLER__.module
    module_name = String.to_atom("#{current_module}.Datacaster#{name}}")

    quote do
      defmodule unquote(module_name) do
        use Datacaster.Transaction

        unquote(block)

        Enum.map(@steps, fn {kind, name} ->
          module_name = unquote(module_name)
          current_module = unquote(current_module)

          delegation = quote do
            defdelegate unquote(name)(params), to: unquote(current_module)
          end

          Module.eval_quoted(unquote(module_name), delegation)
        end)
      end

      def unquote(name)(params) do
        unquote(adapter_module).unquote(adapter_function)(params, &unquote(module_name).run/1)
      end

      @steps @steps ++ [{:within, unquote(name)}]
    end
  end

  def do!(expr) do
    case expr do
      {:ok, result} -> result
      {:error, reason} -> raise Datacaster.Transaction.Exception, reason
    end
  end

  def ok(data), do: {:ok, data}
  def err(reason), do: {:error, reason}

  defp build_step(name, opts, block \\ quote do end) do
    Enum.reduce(opts, block, fn {key, value}, acc ->
      Modifier.modify(name, key, value, acc)
    end)
  end

  defmacro __before_compile__(_) do
    quote do
      Enum.map(@steps, fn {kind, name} ->
        finalizer = Finalizers.finalizer(kind, name, []) 

        if finalizer do
          Module.eval_quoted(__MODULE__, finalizer)
        end
      end)

      def run(params) do
        result = Enum.reduce_while(@steps, params, fn {_kind, name}, acc ->
          case apply(__MODULE__, name, [acc]) do
            {:ok, acc} -> {:cont, acc}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)

        case result do
          {:error, reason} -> {:error, reason}
          success -> {:ok, success}
        end
      rescue
        e in Datacaster.Transaction.Exception -> {:error, e.data}
      end
    end
  end
end
