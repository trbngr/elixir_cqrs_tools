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
  defexception [:query]

  def message(%{query: query}) do
    query
    |> Ecto.Changeset.traverse_errors(&translate_error/1)
    |> inspect()
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end

defmodule Cqrs.CommandError do
  defexception [:command]

  def message(%{command: command}) do
    command
    |> Ecto.Changeset.traverse_errors(&translate_error/1)
    |> inspect()
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
