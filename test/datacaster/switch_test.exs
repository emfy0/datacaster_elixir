defmodule Datacaster.SwitchTest do
  use DatacasterTest

  describe "it works with shortcut definition" do
    define_caster do
      person = hash_schema(
        kind: compare("person"),
        username: string()
      )

      account = hash_schema(
        kind: compare("account"),
        legal_name: string()
      )

      switch(
        :kind, on: %{ person: person, account: account }
      )
    end

    test_caster "returns success for person" do
      assert run_caster(%{
        kind: "person", username: "kane"
      }) == ok(%{
        kind: "person", username: "kane"
      })
    end

    test_caster "returns success for an account" do
      assert run_caster(%{
        kind: "account", legal_name: "Google"
      }) == ok(%{
        kind: "account", legal_name: "Google"
      })
    end

    test_caster "returns failure for person" do
      assert run_caster(%{
        kind: "person", username: 123
      }) == error_map(%{
        username: error("should be a string")
      })
    end

    test_caster "returns failure for account" do
      assert run_caster(%{
        kind: "account", legal_name: true
      }) == error_map(%{
        legal_name: error("should be a string")
      })
    end

    test_caster "returns failure for non match" do
      assert run_caster(%{
        kind: "asd", legal_name: true
      }) == error("is invalid")
    end

    test_caster "returns failure for non pickable" do
      assert run_caster("asd") == error("is not a hash")
    end
  end

  describe "it works with mixed definition" do
    define_caster do
      person = hash_schema(
        kind: compare("person"),
        username: string()
      )

      account = hash_schema(
        kind: compare("account"),
        legal_name: string()
      )

      switch(
        :kind, on: %{ compare("person") => person, compare("account") => account }
      )
    end

    test_caster "returns success for person" do
      assert run_caster(%{
        kind: "person", username: "kane"
      }) == ok(%{
        kind: "person", username: "kane"
      })
    end

    test_caster "returns success for an account" do
      assert run_caster(%{
        kind: "account", legal_name: "Google"
      }) == ok(%{
        kind: "account", legal_name: "Google"
      })
    end

    test_caster "returns failure for person" do
      assert run_caster(%{
        kind: "person", username: 123
      }) == error_map(%{
        username: error("should be a string")
      })
    end

    test_caster "returns failure for account" do
      assert run_caster(%{
        kind: "account", legal_name: true
      }) == error_map(%{
        legal_name: error("should be a string")
      })
    end

    test_caster "returns failure for non match" do
      assert run_caster(%{
        kind: "asd", legal_name: true
      }) == error("is invalid")
    end

    test_caster "returns failure for non pickable" do
      assert run_caster("asd") == error("is not a hash")
    end
  end

  describe "it works with other mixed definition" do
    define_caster do
      person = hash_schema(
        kind: compare("person"),
        username: string()
      )

      account = hash_schema(
        kind: compare("account"),
        legal_name: string()
      )

      switch(

        pick(:kind), on: %{ person: person, account: account }
      )
    end

    test_caster "returns success for person" do
      assert run_caster(%{
        kind: "person", username: "kane"
      }) == ok(%{
        kind: "person", username: "kane"
      })
    end

    test_caster "returns success for an account" do
      assert run_caster(%{
        kind: "account", legal_name: "Google"
      }) == ok(%{
        kind: "account", legal_name: "Google"
      })
    end

    test_caster "returns failure for person" do
      assert run_caster(%{
        kind: "person", username: 123
      }) == error_map(%{
        username: error("should be a string")
      })
    end

    test_caster "returns failure for account" do
      assert run_caster(%{
        kind: "account", legal_name: true
      }) == error_map(%{
        legal_name: error("should be a string")
      })
    end

    test_caster "returns failure for non match" do
      assert run_caster(%{
        kind: "asd", legal_name: true
      }) == error("is invalid")
    end

    test_caster "returns failure for non pickable" do
      assert run_caster("asd") == error("is not a hash")
    end
  end

  describe "it works with plain definition" do
    define_caster do
      person = hash_schema(
        kind: compare("person"),
        username: string()
      )

      account = hash_schema(
        kind: compare("account"),
        legal_name: string()
      )

      switch(
        pick(:kind), on: %{ compare("person") => person, compare("account") => account }
      )
    end

    test_caster "returns success for person" do
      assert run_caster(%{
        kind: "person", username: "kane"
      }) == ok(%{
        kind: "person", username: "kane"
      })
    end

    test_caster "returns success for an account" do
      assert run_caster(%{
        kind: "account", legal_name: "Google"
      }) == ok(%{
        kind: "account", legal_name: "Google"
      })
    end

    test_caster "returns failure for person" do
      assert run_caster(%{
        kind: "person", username: 123
      }) == error_map(%{
        username: error("should be a string")
      })
    end

    test_caster "returns failure for account" do
      assert run_caster(%{
        kind: "account", legal_name: true
      }) == error_map(%{
        legal_name: error("should be a string")
      })
    end

    test_caster "returns failure for non match" do
      assert run_caster(%{
        kind: "asd", legal_name: true
      }) == error("is invalid")
    end

    test_caster "returns failure for non pickable" do
      assert run_caster("asd") == error("is not a hash")
    end
  end
end
