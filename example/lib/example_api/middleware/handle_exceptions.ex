defmodule ExampleApi.Middleware.HandleExceptions do
  @moduledoc false
  require Logger

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution
  alias Ecto.Query.CastError
  alias AbsintheErrorPayload.ChangesetParser
  alias Ecto.{InvalidChangesetError, NoResultsError, StaleEntryError}

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

    e in InvalidChangesetError ->
      errors =
        e.changeset
        |> ChangesetParser.extract_messages()
        |> Enum.map(&"#{&1.field} #{&1.message}")

      Resolution.put_result(resolution, {:error, errors})

    e ->
      Logger.error("Unexpected error", stacktrace: __STACKTRACE__ |> Enum.map(&Tuple.to_list/1))
      Resolution.put_result(resolution, {:error, Exception.message(e)})
  end
end
