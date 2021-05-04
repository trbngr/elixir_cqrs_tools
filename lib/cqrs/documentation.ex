defmodule Cqrs.Documentation do
  @moduledoc false
  alias Cqrs.Documentation

  defmacro field_docs(title, fields, required_fields) do
    quote bind_quoted: [title: title, fields: fields, required_fields: required_fields] do
      {required_fields, optional_fields} =
        Enum.split_with(fields, fn {name, _type, _opts} ->
          Enum.member?(required_fields, name)
        end)

      required_field_docs =
        if length(required_fields) > 0,
          do: Documentation.__fields_docs__(required_fields, "Required")

      optional_field_docs =
        if length(optional_fields) > 0,
          do: Documentation.__fields_docs__(optional_fields, "Optional")

      """
      ## #{title}

      #{required_field_docs}
      #{optional_field_docs}
      """
    end
  end

  defmacro __fields_docs__(fields, title) do
    quote do
      field_docs =
        Enum.map(unquote(fields), fn {name, type, opts} ->
          description =
            case Keyword.get(opts, :description) do
              nil -> nil
              description -> "- #{description}"
            end

          field_type =
            case type do
              Ecto.Enum -> opts |> Keyword.fetch!(:values) |> Enum.join(" | ")
              type when is_tuple(type) -> inspect(type)
              _ -> type
            end

          """

          * `#{name}` :#{field_type} #{description}

          """
        end)

      """
      ### #{unquote(title)} #{field_docs}

      """
    end
  end
end
