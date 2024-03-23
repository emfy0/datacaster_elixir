defmodule Datacaster.ContractTest do
  use ExUnit.Case

  defmodule TestContract do
    use Datacaster.Contract

    define_schema(:base) do
      hash_schema(
        foo: check(&(&1 == :foo)),
        bar: check(&(&1 == :bar))
      )
    end
  end

  TestContract.__datacaster_compile_schemas__()

  test "it maps data" do
    assert TestContract.validate(:base, %{foo: :foo, bar: :bar}) == {:ok, %{"bar" => :bar, "foo" => :foo}}
  end
end
