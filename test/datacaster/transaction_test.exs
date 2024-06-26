defmodule Datacaster.TransactionTest do
  use ExUnit.Case

  defmodule TestOperation1 do
    def run(data) do
      {:ok, put_in(data, [:baz], :baz)}
    end
  end

  defmodule TestOperation2 do
    def run(data) do
      {:ok, put_in(data, [:abc], :abc)}
    end
  end

  defmodule TestTransaction do
    use Datacaster.Transaction

    step :first
    step :second
    step :third, with: TestOperation1
    step :fourth, with: TestOperation2

    def first(data) do
      {:ok, put_in(data, [:foo], :foo)}
    end

    def second(data) do
      {:ok, put_in(data, [:bar], :bar)}
    end

    def fourth(data) do
      result = do! super(data)
      {:ok, put_in(result, [:dsa], :dsa)}
    end
  end

  test "it runs" do
    assert TestTransaction.run(%{}) == {:ok, %{foo: :foo, baz: :baz, bar: :bar, abc: :abc, dsa: :dsa}}
  end

  describe "works with different adapters" do
    defmodule TestTransaction1 do
      use Datacaster.Transaction

      map :first
      tee :second

      def first(data) do
        put_in(data, [:foo], :foo)
      end

      def second(_data) do
        "anything"
      end
    end

    test "it runs" do
      assert TestTransaction1.run(%{}) == {:ok, %{foo: :foo}}
    end
  end

  describe "works with do! notation" do
    defmodule TestTransaction2 do
      use Datacaster.Transaction

      map :first
      step :second
      step :third

      def first(data) do
        put_in(data, [:foo], :foo)
      end

      def second(data) do
        do!({:error, "reason"})

        {:ok, data}
      end

      def third(_data) do
        "anything"
      end
    end

    test "it runs" do
      assert TestTransaction2.run(%{}) == {:error, "reason"}
    end
  end

  describe "works with do! for unwrap" do
    defmodule TestTransaction3 do
      use Datacaster.Transaction

      map :first
      map :second
      tee :third

      def first(data) do
        put_in(data, [:foo], :foo)
      end

      def second(data) do
        do!({:ok, put_in(data, [:bar], :bar)})
      end

      def third(_data) do
        "anything"
      end
    end

    test "it runs" do
      assert TestTransaction3.run(%{}) == {:ok, %{foo: :foo, bar: :bar}}
    end
  end

  describe "works with within" do
    defmodule TestTransaction5.WithinExt do
      use Datacaster.Transaction

      def second(data, callable) do
        data = data ++ ["second1"]
        data = do! callable.(data)
        ok(data ++ ["second2"])
      end
    end

    defmodule TestTransaction5 do
      use Datacaster.Transaction

      map :first

      within TestTransaction5.WithinExt, :second do
        map :third
        map :fourth
      end

      within TestTransaction5.WithinExt, :second do
        map :fifth
        map :sixth
      end

      def first(data) do
        data ++ ["first"]
      end

      def third(data) do
        data ++ ["third"]
      end

      def fourth(data) do
        data ++ ["fourth"]
      end

      def fifth(data) do
        data ++ ["fifth"]
      end

      def sixth(data) do
        data ++ ["sixth"]
      end
    end

    test "it runs" do
      assert TestTransaction5.run([]) == {
        :ok, ["first", "second1", "third", "fourth", "second2", "second1", "fifth", "sixth", "second2"]
      }
    end
  end
end
