defmodule Cqrs.Command.CommandError do
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
