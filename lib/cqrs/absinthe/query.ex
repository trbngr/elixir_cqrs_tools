if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Query do
    @moduledoc false
    alias Cqrs.{BoundedContext, Absinthe.Args, Absinthe.Metadata, Absinthe.Middleware, Absinthe.Query}

    def create_connection_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)

      opts =
        :cqrs_tools
        |> Application.get_env(:absinthe_relay, [])
        |> Keyword.merge(opts)

      repo = Keyword.fetch!(opts, :repo)

      quote do
        require Middleware

        connection field unquote(function_name), node_type: unquote(returns) do
          unquote_splicing(query_args)

          Middleware.before_resolve(unquote(query_module), unquote(opts))

          resolve(fn parent, args, resolution ->
            alias Absinthe.Relay.Connection

            args =
              parent
              |> Query.read_filters_from_parent(unquote(opts))
              |> Map.merge(args)

            opts = Metadata.merge(resolution, unquote(opts))

            case BoundedContext.__create_query__(unquote(query_module), args, opts) do
              {:error, error} ->
                {:error, error}

              {:ok, query} ->
                repo_fun = fn args ->
                  fun = Keyword.get(unquote(opts), :repo_fun, :all)
                  apply(unquote(repo), fun, [args])
                end

                Connection.from_query(query, repo_fun, args)
            end
          end)

          Middleware.after_resolve(unquote(query_module), unquote(opts))
        end
      end
    end

    def create_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)

      quote do
        require Middleware

        field unquote(function_name), unquote(returns) do
          unquote_splicing(query_args)

          Middleware.before_resolve(unquote(query_module), unquote(opts))

          resolve(fn parent, args, resolution ->
            opts =
              resolution
              |> Metadata.merge(unquote(opts))
              |> Keyword.put(:tag?, true)

            args =
              parent
              |> Query.read_filters_from_parent(unquote(opts))
              |> Map.merge(args)

            case BoundedContext.__execute_query__(unquote(query_module), args, opts) do
              {:ok, result} ->
                {:ok, result}

              {:error, map} when is_map(map) ->
                {:error,
                 Enum.reduce(map, [], fn {key, messages}, acc ->
                   acc ++ Enum.map(messages, fn msg -> "#{key} #{msg}" end)
                 end)}

              {:error, errors} ->
                {:error, errors}
            end
          end)

          Middleware.after_resolve(unquote(query_module), unquote(opts))
        end
      end
    end

    defp create_query_args(query_module, opts) do
      filters_from_parent = opts |> filters_from_parent() |> Keyword.keys()

      query_module.__filters__()
      |> Enum.reject(fn {filter, _, _} -> Enum.member?(filters_from_parent, filter) end)
      |> Args.extract_args(opts)
      |> Enum.map(fn {name, absinthe_type, required, opts} ->
        case required do
          true -> quote do: arg(unquote(name), non_null(unquote(absinthe_type)), unquote(opts))
          false -> quote do: arg(unquote(name), unquote(absinthe_type), unquote(opts))
        end
      end)
    end

    defp filters_from_parent(opts) do
      Keyword.get(opts, :filters_from_parent, [])
    end

    def read_filters_from_parent(parent, opts) do
      opts
      |> filters_from_parent()
      |> Enum.reduce(%{}, fn {filter, parent_field}, acc ->
        Map.put(acc, filter, Map.get(parent, parent_field))
      end)
    end
  end
end
