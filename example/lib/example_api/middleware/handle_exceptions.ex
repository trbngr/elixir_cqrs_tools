defmodule ExampleApi.Middleware.HandleExceptions do
  @moduledoc false
  require Logger

  @behaviour Absinthe.Middleware

  alias Cqrs.CommandError
  alias Absinthe.Resolution
  alias Ecto.Query.CastError
  alias Ecto.{NoResultsError, StaleEntryError}

  def apply(middleware) when is_list(middleware) do
    Enum.map(middleware, fn
      {{Resolution, :call}, resolver} -> {__MODULE__, resolver}
      other -> other
    end)
  end

  @impl true
  def call(resolution, resolver) do
    Resolution.call(resolution, resolver)
  rescue
    e in CastError ->
      type = if e.type === :binary_id, do: :uuid, else: e.type
      error = [message: "Invalid argument", type: type, value: e.value, status: 400]
      Resolution.put_result(resolution, {:error, error})

    _ in NoResultsError ->
      error = [message: "Not found", status: 404]
      Resolution.put_result(resolution, {:error, error})

    e in StaleEntryError ->
      Resolution.put_result(
        resolution,
        {:error, [message: "Not found.", status: 404, detail: Exception.message(e)]}
      )

    e in CommandError ->
      errors =
        e.command
        |> Ecto.Changeset.traverse_errors(fn {msg, opts} ->
          Enum.reduce(opts, msg, fn {key, value}, acc ->
            String.replace(acc, "%{#{key}}", to_string(value))
          end)
        end)

      Resolution.put_result(resolution, {:error, errors})

    e ->
      __STACKTRACE__|> IO.inspect(label: "__STACKTRACE__")
      Logger.error("Unexpected error", stacktrace: __STACKTRACE__ |> Enum.map(&Tuple.to_list/1))
      Resolution.put_result(resolution, {:error, Exception.message(e)})
  end
end
