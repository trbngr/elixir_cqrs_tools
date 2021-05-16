defmodule Cqrs.Documentation do
  @moduledoc false
  alias Cqrs.Documentation

  defmacro option_docs(options) do
    quote bind_quoted: [options: options] do
      docs =
        options
        |> Enum.sort_by(&elem(&1, 0))
        |> Enum.map(fn
          {name, {:enum, possible_values}, opts} ->
            default = Documentation.option_default(opts)
            description = Documentation.option_description(opts)

            values =
              possible_values
              |> Enum.map(&"`#{&1}`")
              |> Enum.join(" | ")

            "* `#{name}`: `:enum`.#{description}Possible values: #{values}. Defaults to `#{inspect(default)}`."

          {name, hint, opts} ->
            default = Documentation.option_default(opts)
            description = Documentation.option_description(opts)

            hint =
              cond do
                is_binary(hint) -> hint
                true -> inspect(hint)
              end
            "* `#{name}`: `#{hint}`.#{description}Defaults to `#{inspect(default)}`"
        end)

      if length(docs) > 0 do
        """
        ## Options

        #{Enum.join(docs, "\n")}
        """
      else
        ""
      end
    end
  end

  def option_default(opts) do
    Keyword.get(opts, :default, "nil")
  end

  def option_description(opts) do
    case Keyword.get(opts, :description) do
      nil -> ""
      desc -> " #{String.trim_trailing(desc, ".")}. "
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
        |> Enum.sort_by(&elem(&1, 0))
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
              default -> "Defaults to `#{inspect(default)}`."
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
