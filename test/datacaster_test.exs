defmodule DatacasterTest do
  use ExUnit.Case
  doctest Datacaster

  use Datacaster

  import DatacasterTestHelper
  alias Datacaster.{Error, Success, Executor, Context}

  def build_context(val, error \\ nil) do
    Map.put(val, :__datacaster__, Context.new())
    |> Context.put_error(error)
  end

  describe "#cast" do
    test "creates caster with lambda" do
      caster = Datacaster.schema do
        cast(fn input ->
          Success.new(input["foo"] == context[:bar])
        end)
      end
   
      assert run_caster(caster, %{foo: :bar}, %{bar: :bar}) == Success.new(true)
    end
    
    test "it works with & syntax" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1["foo"] == :bar)))
      end
   
      assert run_caster(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(true)
    end

    test "it works with & syntax and context" do
      caster = Datacaster.schema do
        cast(&(Success.new(&1["foo"] == &2[:bar])))
      end
   
      assert run_caster(caster, %{foo: :bar}, %{bar: :bar}) == Success.new(true)
    end
  end

  describe "#check" do
    test "builds checker ok monad on success" do
      caster = Datacaster.schema do
        check("error", fn _ ->
          context.a == 2
        end)
      end

      assert run_caster(caster, 2, %{a: 2}) == %Success{value: 2}
      assert run_caster(caster, 3, %{a: 3}) == %Error{error: "error", context: build_context(%{a: 3}, 3)}
    end
  end

  describe "definition syntax" do
    test "it works with > syntax" do
      caster = Datacaster.schema do
        check(&(&1["foo"] == :bar)) > check(fn -> context[:bar] == :baz end)
      end

      assert run_caster(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "it works with <> syntax" do
      caster = Datacaster.schema do
        check(&(&1["foo"] == :not_bar)) <> check(fn -> context[:bar] == :baz end)
      end

      assert run_caster(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "> operator works in lambdas" do
      caster = Datacaster.schema do
        check(fn input ->
          input > context.a
        end)
      end

      assert run_caster(caster, 3, %{a: 2}) == Success.new(3)
    end

    test "it sets context on error" do
      caster = Datacaster.schema do
        check(fn input ->
          context = Map.put(context, :b, 3)

          input < context.a
        end)
      end

      assert run_caster(caster, 3, %{a: 2}) == Error.new("invalid", build_context(%{a: 2, b: 3}, 3))
    end
  end

  describe "#hash" do
    test "it works with hash" do
      caster = Datacaster.schema(do: hash())

      assert run_caster(caster, %{foo: :bar}, %{bar: :baz}) == Success.new(%{"foo" => :bar})
    end

    test "it returns error on non-hash" do
      caster = Datacaster.schema(do: hash())

      assert run_caster(caster, 1, %{bar: :baz}) == Error.new("should be a hash", build_context(%{bar: :baz}, 1))
    end
  end

  describe "#included_in" do
    test "it works with included_in" do
      caster = Datacaster.schema do
        included_in([1, 2, 3])
      end

      assert run_caster(caster, 1, %{bar: :baz}) == Success.new(1)
      assert run_caster(caster, 4, %{bar: :baz}) == Error.new("should be included in [1, 2, 3]", build_context(%{bar: :baz}, 4))
    end
  end

  describe "#transform" do
    test "it works with transform" do
      caster = Datacaster.schema do
        transform(fn input ->
          input + 1
        end)
      end

      assert run_caster(caster, 1, %{bar: :baz}) == Success.new(2)
    end

    test "in works with & syntax" do
      caster = Datacaster.schema do
        transform(&(&1 + 1))
      end

      assert run_caster(caster, 1, %{bar: :baz}) == Success.new(2)
    end
  end

  describe "#run" do
    test "it works with run" do
      caster = Datacaster.schema do
        runner = run(fn input, context ->
          context = Map.put(context, :type, input["type"])
        end)

        runner > check("error", fn _ ->
          context[:type] == "user"
        end)
      end

      input = %{
        type: "user",
      }

      assert run_caster(caster, input, %{bar: :baz}) == Success.new(Executor.stringify_keys(input))
    end
  end

  describe "#remove" do
    test "it works with remove" do
      caster = Datacaster.schema do
        remove()
      end

      assert run_caster(caster, 1, %{bar: :baz}) == Success.new(Datacaster.Absent)
    end
  end

  describe "#optional" do
    test "it works with optional" do
      caster = Datacaster.schema do
        hash_schema(
          foo: optional(string()),
          bar: string()
        )
      end

      assert run_caster(caster, %{foo: "bar", bar: "baz"}) == Success.new(%{"foo" => "bar", "bar" => "baz"})
      assert run_caster(caster, %{bar: "baz"}) == Success.new(%{"bar" => "baz"})
      assert run_caster(caster, %{foo: 1, bar: "baz"}) == %Error.Map{
        errors: %{
          "foo" => Error.new("should be a string", build_context(%{}, 1))
        }
      }
    end


    test "it works wiht :on keyword" do
      caster = Datacaster.schema do
        hash_schema(
          foo: optional(string(), on: ""),
          bar: string()
        )
      end

      assert run_caster(caster, %{foo: "bar", bar: "baz"}) == Success.new(%{"foo" => "bar", "bar" => "baz"})
      assert run_caster(caster, %{bar: "baz", foo: ""}) == Success.new(%{"bar" => "baz"})
      assert run_caster(caster, %{foo: 1, bar: "baz"}) == %Error.Map{
        errors: %{
          "foo" => Error.new("should be a string", build_context(%{}, 1))
        }
      }
    end
  end

  describe "#iso_8601" do
    test "it works with iso_8601" do
      caster = Datacaster.schema do
        iso_8601()
      end

      {:ok, result, _} = DateTime.from_iso8601("2018-01-01T00:00:00Z") 
      assert run_caster(caster, "2018-01-01T00:00:00Z") == Success.new(result)
      assert run_caster(caster, "2018-01-01T00:00:00") == Error.new(
        "should be an ISO 8601 date", build_context(%{}, "2018-01-01T00:00:00")
      )
    end
  end

  describe "#non_empty_string" do
    test "it works with non_empty_string" do
      caster = Datacaster.schema do
        non_empty_string()
      end

      assert run_caster(caster, "foo") == Success.new("foo")
      assert run_caster(caster, "") == Error.new("should be a non-empty string", build_context(%{}, ""))
    end
  end

  describe "#to_integer" do
    test "it works with integer" do
      caster = Datacaster.schema do
        to_integer()
      end

      assert run_caster(caster, "1") == Success.new(1)
      assert run_caster(caster, "foo") == Error.new("should be an integer", build_context(%{}, "foo"))
      assert run_caster(caster, 1) == Success.new(1)
    end
  end

  describe "#to_float" do
    test "it works with float" do
      caster = Datacaster.schema do
        to_float()
      end

      assert run_caster(caster, "1.0") == Success.new(1.0)
      assert run_caster(caster, "foo") == Error.new("should be a float", build_context(%{}, "foo"))
      assert run_caster(caster, 1.0) == Success.new(1.0)
    end
  end

  describe "#to_boolean" do
    test "it works with boolean" do
      caster = Datacaster.schema do
        to_boolean()
      end

      assert run_caster(caster, "true") == Success.new(true)
      assert run_caster(caster, "false") == Success.new(false)
      assert run_caster(caster, 1) == Success.new(true)
      assert run_caster(caster, 0) == Success.new(false)
      assert run_caster(caster, "foo") == Error.new("should be a boolean", build_context(%{}, "foo"))
    end
  end
end
