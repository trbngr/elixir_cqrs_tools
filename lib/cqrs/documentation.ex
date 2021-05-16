defmodule Cqrs.Documentation do
  @moduledoc false
  alias Cqrs.Documentation

  defmacro option_docs(options) do
    quote bind_quoted: [options: options] do
      docs =
        Enum.map(options, fn {name, type, opts} ->
          default = Keyword.get(opts, :default, "nil")

          description =
            case Keyword.get(opts, :description) do
              nil -> ""
              desc -> """

                #{desc}
              """
            end

            type = cond do
              is_binary(type) -> type
              true -> inspect(type)
            end

          "* `#{name}`: `#{type}`. Defaults to `#{inspect(default)}`.#{description}\n"
        end)

      if length(docs) > 0 do
        """
        ## Options

        #{docs}
        """
      else
        ""
      end
    end
  end

  defmacro field_docs(title, fields, required_fields) do
    quote bind_quoted: [title: title, fields: fields, required_fields: required_fields] do
      {required_fields, optional_fields} =
        Enum.split_with(fields, fn {name, _type, _opts} ->
          Enum.member?(required_fields, name)
        end)

      required_field_docs = Documentation.__fields_docs__(required_fields, "Required")
      optional_field_docs = Documentation.__fields_docs__(optional_fields, "Optional")

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
        unquote(fields)
        |> Enum.reject(fn {_name, _type, opts} -> Keyword.get(opts, :internal, false) end)
        |> Enum.map(fn {name, type, opts} ->
          description =
            case Keyword.get(opts, :description) do
              nil -> ""
              desc -> ". " <> String.trim_trailing(desc, ".") <> "."
            end

          field_type =
            case type do
              Ecto.Enum -> opts |> Keyword.fetch!(:values) |> Enum.join(" | ")
              type when is_tuple(type) -> inspect(type)
              _ -> type
            end

            defaults =
              case Keyword.get(opts, :default) do
                nil -> nil
                default ->  "Defaults to `#{inspect(default)}`."
              end

          """
          * `#{name}`: `#{field_type}`#{description} #{defaults}
          """
        end)

      if length(field_docs) > 0 do
        """
        ### #{unquote(title)}

        #{field_docs}
        """
      end
    end
  end
end
