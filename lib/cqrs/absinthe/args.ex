if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Args do
    @moduledoc false
    def extract_args(fields, opts) do
      only = Keyword.get(opts, :only, [])
      except = Keyword.get(opts, :except, [])

      fields =
        case {only, except} do
          {[], []} -> fields
          {[], except} -> Enum.reject(fields, &Enum.member?(except, elem(&1, 0)))
          {only, []} -> Enum.filter(fields, &Enum.member?(only, elem(&1, 0)))
          _ -> raise "You can only specify :only or :except"
        end

      fields
      |> Enum.reject(fn {_name, _type, opts} -> Keyword.get(opts, :internal, false) == true end)
      |> Enum.map(fn field ->
        {name, _type, field_opts} = field
        absinthe_type = absinthe_type(field, opts)
        required = Keyword.get(field_opts, :required, false)
        {name, absinthe_type, required}
      end)
    end

    defp absinthe_type({name, {:array, type}, _}, opts) do
      type = absinthe_type({name, type, nil}, opts)
      quote do: list_of(unquote(type))
    end

    defp absinthe_type({name, Ecto.Enum, _}, opts) do
      source = Keyword.get(opts, :source)
      macro = Keyword.get(opts, :macro)

      enum_type =
        opts
        |> Keyword.get(:arg_types, [])
        |> Keyword.get(name) ||
          raise Cqrs.Absinthe.EnumTypeMappingError, source: source, macro: macro, type: name

      quote do: unquote(enum_type)
    end

    defp absinthe_type({_name, :binary_id, _}, _opts), do: quote(do: :id)
    defp absinthe_type({_name, type, _}, _opts), do: quote(do: unquote(type))
  end
end
