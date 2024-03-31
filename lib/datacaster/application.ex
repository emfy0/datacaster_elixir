defmodule Datacaster.Application do
  use Application

  def start(_, _) do
    for {application,_,_} <- Application.loaded_applications(),
      deps = Application.spec(application)[:applications],
      :datacaster in deps
    do
      {:ok, modules} = :application.get_key(application, :modules)

      for module <- modules,
        Keyword.has_key?(module.__info__(:functions), :__datacaster_compile_schemas__),
        do: module.__datacaster_compile_schemas__()
    end

    {:ok, self()}
  end
end
