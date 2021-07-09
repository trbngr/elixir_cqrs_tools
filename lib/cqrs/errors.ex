defmodule Cqrs.InvalidCommandError do
  defexception [:command]

  def message(%{command: module}),
    do: "#{module |> Module.split() |> Enum.join(".")} is not a Cqrs.Command"
end

defmodule Cqrs.InvalidQueryError do
  defexception [:query]

  def message(%{query: module}),
    do: "#{module |> Module.split() |> Enum.join(".")} is not a Cqrs.Query"
end

defmodule Cqrs.InvalidRouterError do
  defexception [:router]

  def message(%{router: module}),
    do: "#{module |> Module.split() |> Enum.join(".")} is not a Commanded.Commands.Router"
end

defmodule Cqrs.InvalidDispatcherError do
  defexception [:dispatcher]

  def message(%{dispatcher: module}),
    do: "#{module |> Module.split() |> Enum.join(".")} is required to export a dispatch/2 function."
end

defmodule Cqrs.QueryError do
  defexception [:errors]

  def message(%{errors: errors}) do
    errors
    |> Enum.flat_map(fn {key, messages} -> Enum.map(messages, fn msg -> "#{key} #{msg}" end) end)
    |> Enum.join("\n")
  end
end

defmodule Cqrs.CommandError do
  defexception [:errors]

  def message(%{errors: errors}) do
    errors
    |> Enum.flat_map(fn {key, messages} -> Enum.map(messages, fn msg -> "#{key} #{msg}" end) end)
    |> Enum.join("\n")
  end
end

defmodule Cqrs.ValueObjectError do
  defexception [:errors]

  def message(%{errors: errors}) do
    errors
    |> Enum.flat_map(fn {key, messages} -> Enum.map(messages, fn msg -> "#{key} #{msg}" end) end)
    |> Enum.join("\n")
  end
end

defmodule Cqrs.InvalidValuesError do
  defexception [:module]

  def message(%{module: module}) do
    "Values passed to #{inspect(module)} must be either a keyword list, a map, or a struct"
  end
end
