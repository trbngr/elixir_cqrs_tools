if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe do
    defmacro __using__(_) do
      quote do
        import Cqrs.Absinthe, only: [query_args: 1, query_args: 2]
      end
    end

    @doc """
    Creates args for an `Absinthe` query from a [query's](`Cqrs.Query`) filters.

    ## Options

    * `:only` - Restrict importing to only the filters listed
    * `:except` - Imports all filters except for those listed
    * any filter name to an existing absinthe_type

    ## Examples
        field :user, :user do
          query_args GetUser, except: [:name]
          resolve &user/2
        end

        connection field :users, node_type: :user do
          query_args ListUsers, status: :user_status
          resolve &users/2
        end

    """
    defmacro query_args(query_module, opts \\ []) do
      query_args = __create_query_args__(query_module, opts)
      Module.eval_quoted(__CALLER__, query_args)
    end

    def __create_query_args__(query_module, opts) do
      quote do
        _ = unquote(query_module).__info__(:functions)

        unless function_exported?(unquote(query_module), :__query__, 0) do
          raise Cqrs.BoundedContext.InvalidQueryError, query: unquote(query_module)
        end

        filters = Cqrs.Absinthe.__extract_filters__(unquote(query_module), unquote(opts))
        |> Enum.map(fn {name, absinthe_type, required} ->
          case required do
            true -> quote do: arg(unquote(name), non_null(unquote(absinthe_type)))
            false -> quote do: arg(unquote(name), unquote(absinthe_type))
          end
        end)
      end
    end

    def __extract_filters__(query_module, opts) do
      filters = query_module.__filters__()

      only = Keyword.get(opts, :only, [])
      except = Keyword.get(opts, :except, [])

      filters =
        case {only, except} do
          {[], []} -> filters
          {[], except} -> Enum.reject(filters, &Enum.member?(except, elem(&1, 0)))
          {only, []} -> Enum.filter(filters, &Enum.member?(only, elem(&1, 0)))
          _ -> raise "You can only specify :only or :except"
        end

      Enum.map(filters, fn filter ->
        {name, _type, filter_opts} = filter
        absinthe_type = Cqrs.Absinthe.__absinthe_type__(filter, opts)
        required = Keyword.get(filter_opts, :required, false)
        {name, absinthe_type, required}
      end)
    end

    def __absinthe_type__({name, Ecto.Enum, _}, opts) do
      enum_type = Keyword.get(opts, name) || raise "Must supply absinthe enum type for #{name}"
      quote do: unquote(enum_type)
    end

    def __absinthe_type__({_name, :binary_id, _}, _opts), do: quote(do: :id)
    def __absinthe_type__({_name, type, _}, _opts), do: quote(do: unquote(type))
  end
end
