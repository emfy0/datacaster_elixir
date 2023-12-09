defmodule Datacaster.Error do
  defstruct error: nil, context: nil

  defmodule List do
    defstruct errors: []

    def from_error(error) do
      %__MODULE__{errors: [error]}
    end

    def merge(left = %__MODULE__{}, right = %__MODULE__{}) do
      %__MODULE__{
        errors: left.errors ++ right.errors
      }
    end
  end

  defmodule Map do
    defstruct errors: %{}

    alias Datacaster.Error

    def new(key, error = %Error{}) do
      %__MODULE__{
        errors: %{key => [error]}
      }
    end

    def from_list(errors = %List{}) do
      %__MODULE__{errors: %{base: errors}}
    end

    def add_key(map = %__MODULE__{}, key, error) do
      current = Elixir.Map.get(map.errors, key)

      new =
        if is_nil(current) do
          error
        else
          Error.merge(current, error)
        end

      %__MODULE__{
        map | errors: put_in(map.errors, [key], new)
      }
    end

    def merge(left = %__MODULE__{}, right = %__MODULE__{}) do
      %__MODULE__{
        errors: merge_maps(left.errors, right.errors)
      }
    end

    def merge_maps(left, right) do
      Enum.reduce(right, left, fn {key, value}, acc ->
        Elixir.Map.update(acc, key, value, fn current ->
          Map.merge(current, value)
        end)
      end)
    end
  end

  def merge(left = %List{}, right = %List{}) do
    List.merge(left, right)
  end

  def merge(left = %Map{}, right = %Map{}) do
    Map.merge(left, right)
  end

  def merge(left = %List{}, right = %Map{}) do
    Map.merge(
      Map.from_list(left),
      right
    )
  end

  def merge(left = %Map{}, right = %List{}) do
    Map.merge(
      left,
      Map.from_list(right)
    )
  end

  def merge(left = %__MODULE__{}, right = %List{}) do
    List.merge(
      List.from_error(left),
      right
    )
  end

  def merge(left = %List{}, right = %__MODULE__{}) do
    List.merge(
      left,
      List.from_error(right)
    )
  end

  def merge(left = %__MODULE__{}, right = %Map{}) do
    Map.merge(
      Map.new(:base, left),
      right
    )
  end

  def merge(left = %Map{}, right = %__MODULE__{}) do
    Map.merge(
      left,
      Map.new(:base, right)
    )
  end

  def merge(left = %__MODULE__{}, right = %__MODULE__{}) do
    List.merge(
      List.from_error(left), List.from_error(right)
    )
  end

  def new(value = %Datacaster.Success{}) do
    value
  end

  def new(value = %__MODULE__{}) do
    value
  end

  def new(error, context \\ nil) do
    %__MODULE__{error: error, context: context}
  end
end
