defmodule Datacaster.Compiler do
  def precompile_schemas!(caller_module \\ nil) do
    application =
      if caller_module do
        Application.get_application(caller_module)
      else
        Mix.Project.get.project[:app]     
      end

    {:ok, modules} = :application.get_key(application, :modules)

    modules
      |> Enum.filter(fn module ->
        module.__info__(:functions) |> Keyword.has_key?(:__datacaster_compile_schemas__)
      end)
      |> Enum.each(&(&1.__datacaster_compile_schemas__()))
  end
end
