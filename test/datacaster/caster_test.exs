defmodule Datacaster.CasterTest do
  use DatacasterTest

  describe "#caster" do
    define_caster do
      a = caster(fn input ->
        context = Map.put(context, :test, :context_val)
        ok(input ++ [:a])
      end)

      b = caster(fn input ->
        ok(input ++ [context.test])
      end)

      c = check("!!!!", fn -> false end) <> check("!!!", fn -> true end)

      a > b > c
    end

    test_caster "it works" do
      assert run_caster([:some_value]) == ok([:some_value, :a, :context_val])
    end
  end

  describe "#to_boolean" do
    define_caster do
      to_boolean()
    end

    test_caster "return error on non boolean" do
      assert run_caster("unknown") == error("should be a boolean")
    end

    test_caster "return success on boolean" do
      assert run_caster("1") == ok(true)
    end
  end

  describe "#uuid" do
    define_caster do
      uuid()
    end

    test_caster "return error on non uuid" do
      assert run_caster("unknown") == error("should be a uuid")
    end

    test_caster "return success on uuid" do
      assert run_caster("eadaab09-56a0-46b0-8ef4-14c417f1d632") == ok("eadaab09-56a0-46b0-8ef4-14c417f1d632")
    end

    test_caster "return success on upcase uuid" do
      assert run_caster("EADAAB09-56A0-46B0-8EF4-14C417F1D632") == ok("EADAAB09-56A0-46B0-8EF4-14C417F1D632")
    end
  end

  describe "#boolean" do
    define_caster do
      boolean()
    end

    test_caster "return error on non boolean" do
      assert run_caster("true") == error("should be a boolean")
    end

    test_caster "return success on boolean" do
      assert run_caster(true) == ok(true)
    end
  end

  describe "#float" do
    define_caster do
      float()
    end

    test_caster "return error on non float" do
      assert run_caster("unknown") == error("should be a float")
    end

    test_caster "return success on float" do
      assert run_caster(1.2) == ok(1.2)
    end
  end

  describe "#hash" do
    define_caster do
      hash()
    end

    test_caster "return error on non hash" do
      assert run_caster("unknown") == error("should be a hash")
    end

    test_caster "return success on hash" do
      assert run_caster(%{a: :b}) == ok(%{a: :b})
    end
  end
end
