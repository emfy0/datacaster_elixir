defmodule Datacaster.HashSchemaTest do
  use DatacasterTest

  describe "simple #hash_schema" do
    define_caster do
      hash_schema(
        a: string(),
        b: uuid()
      )
    end

    test_caster "return error on non hash" do
      assert run_caster("unknown") == error("is not a hash")
    end

    test_caster "return success on hash" do
      assert run_caster(
        %{a: "b", b: "b0846814-3ed3-4467-91f9-068229f6573e"}
      ) == ok(
        %{a: "b", b: "b0846814-3ed3-4467-91f9-068229f6573e"}
      )
    end

    test_caster "return error on invalid_data" do
      assert run_caster(%{a: "b", b: "asd"}) == error_map(%{
        b: error("should be a uuid")
      })
    end
  end

  describe "composition #hash_schema" do
    define_caster do
      hash_schema(
        a: string()
      ) > hash_schema(
        b: uuid()
      )
    end

    test_caster "return error on non hash" do
      assert run_caster("unknown") == error("is not a hash")
    end

    test_caster "return success on hash" do
      assert run_caster(
        %{a: "b", b: "b0846814-3ed3-4467-91f9-068229f6573e"}
      ) == ok(
        %{a: "b", b: "b0846814-3ed3-4467-91f9-068229f6573e"}
      )
    end

    test_caster "return error on invalid_data" do
      assert run_caster(%{a: "b", b: "asd"}) == error_map(%{
        b: error("should be a uuid")
      })
    end
  end

  describe "nested #hash_schema" do
    define_caster do
      hash_schema(
        a: string(),
        c: hash_schema(
          b: uuid()
        )
      ) 
    end

    test_caster "return error on non hash" do
      assert run_caster("unknown") == error("is not a hash")
    end

    test_caster "return success on hash" do
      assert run_caster(
        %{a: "b", c: %{ b: "b0846814-3ed3-4467-91f9-068229f6573e"} }
      ) == ok(
        %{a: "b", c: %{ b: "b0846814-3ed3-4467-91f9-068229f6573e"} }
      )
    end

    test_caster "return error on invalid_data" do
      assert run_caster(%{a: "b", b: "asd"}) == error_map(%{
        c: error("is not a hash")
      })
    end
  end
end
