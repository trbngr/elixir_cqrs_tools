if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Query do
    alias Cqrs.{BoundedContext, Absinthe.Query}

    defmacro derive_query(query_module, returns, opts \\ []) do
      field =
        quote do
          Query.__create_query__(
            unquote(query_module),
            unquote(returns),
            unquote(opts)
          )
        end

      Module.eval_quoted(__CALLER__, field)
    end

    defmacro derive_connection(query_module, returns, opts) do
      field =
        quote do
          Query.__create_connection_query__(
            unquote(query_module),
            unquote(returns),
            unquote(opts)
          )
        end

      Module.eval_quoted(__CALLER__, field)
    end

    def __create_connection_query__(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      opts = Keyword.merge(opts, [source: query_module, macro: :derive_connection])
      query_args = Query.__create_query_args__(query_module, opts)
      repo = Keyword.fetch!(opts, :repo)

      quote do
        _ = unquote(query_module).__info__(:functions)

        unless function_exported?(unquote(query_module), :__query__, 0) do
          raise Cqrs.BoundedContext.InvalidQueryError, query: unquote(query_module)
        end

        connection field unquote(function_name), node_type: unquote(returns) do
          unquote_splicing(query_args)

          resolve(fn args, _resolution ->
            alias Absinthe.Relay.Connection

            case BoundedContext.__create_query__!(unquote(query_module), args, unquote(opts)) do
              {:error, error} ->
                {:error, error}

              query ->
                repo_fun = fn args ->
                  fun = Keyword.get(unquote(opts), :repo_fun, :all)
                  apply(unquote(repo), fun, [args])
                end

                Connection.from_query(query, repo_fun, args)
            end
          end)
        end
      end
    end

    def __create_query__(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      opts = Keyword.merge(opts, [source: query_module, macro: :derive_query])
      query_args = Query.__create_query_args__(query_module, opts)

      quote do
        _ = unquote(query_module).__info__(:functions)

        unless function_exported?(unquote(query_module), :__query__, 0) do
          raise Cqrs.BoundedContext.InvalidQueryError, query: unquote(query_module)
        end

        field unquote(function_name), unquote(returns) do
          unquote_splicing(query_args)

          resolve(fn attrs, _resolution ->
            case BoundedContext.__execute_query__!(unquote(query_module), attrs, unquote(opts)) do
              {:ok, results} -> {:ok, results}
              {:error, error} -> {:error, error}
              results -> {:ok, results}
            end
          end)
        end
      end
    end

    def __create_query_args__(query_module, opts) do
      query_module.__filters__()
      |> Cqrs.Absinthe.__extract_fields__(opts)
      |> Enum.map(fn {name, absinthe_type, required} ->
        case required do
          true -> quote do: arg(unquote(name), non_null(unquote(absinthe_type)))
          false -> quote do: arg(unquote(name), unquote(absinthe_type))
        end
      end)
    end
  end
end
