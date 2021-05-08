if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe do

    defmacro __using__(_) do
      quote do
        import Cqrs.Absinthe.Mutation,
          only: [
            derive_mutation_input: 1,
            derive_mutation_input: 2,
            derive_mutation: 2,
            derive_mutation: 3
          ]

        import Cqrs.Absinthe.Query,
          only: [
            derive_query: 2,
            derive_query: 3,
            derive_connection: 3
          ]
      end
    end

    def __extract_fields__(fields, opts) do
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
        absinthe_type = Cqrs.Absinthe.__absinthe_type__(field, opts)
        required = Keyword.get(field_opts, :required, false)
        {name, absinthe_type, required}
      end)
    end

    def __absinthe_type__({name, Ecto.Enum, _}, opts) do
      source  = Keyword.get(opts, :source)
      macro  = Keyword.get(opts, :macro)
      enum_type = Keyword.get(opts, name) || raise Cqrs.Absinthe.EnumTypeMappingError, source: source, macro: macro, type: name
      quote do: unquote(enum_type)
    end

    def __absinthe_type__({_name, :binary_id, _}, _opts), do: quote(do: :id)
    def __absinthe_type__({_name, type, _}, _opts), do: quote(do: unquote(type))
  end
end
