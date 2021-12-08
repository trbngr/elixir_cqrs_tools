if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Query do
    @moduledoc false
    alias Cqrs.{
      BoundedContext,
      Absinthe.Args,
      Absinthe.DefaultOpts,
      Absinthe.Metadata,
      Absinthe.Middleware,
      Absinthe.FieldMapping
    }

    def create_connection_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)
      description = query_module.__simple_moduledoc__()
      {before_resolve, after_resolve} = Middleware.middleware(opts)

      opts =
        :cqrs_tools
        |> Application.get_env(:absinthe_relay, [])
        |> Keyword.merge(opts)

      repo = Keyword.fetch!(opts, :repo)

      quote do
        require Middleware

        connection field unquote(function_name), node_type: unquote(returns) do
          unquote_splicing(query_args)
          description unquote(description)

          middleware unquote(before_resolve)

          resolve(fn parent, args, resolution ->
            alias Absinthe.Relay.Connection

            args =
              args
              |> FieldMapping.resolve_parent_mappings(unquote(query_module), parent, args, unquote(opts))
              |> FieldMapping.run_field_transformations(unquote(query_module), unquote(opts))

            opts =
              resolution
              |> Metadata.merge(unquote(opts))
              |> DefaultOpts.set()

            case BoundedContext.__create_query__(unquote(query_module), args, opts) do
              {:error, error} ->
                {:error, error}

              {:ok, query} ->
                repo_fun = fn args ->
                  fun = Keyword.get(unquote(opts), :repo_fun, :all)
                  apply(unquote(repo), fun, [args])
                end

                with {:ok, result} <- Connection.from_query(query, repo_fun, args) do
                  result =
                    result
                    |> Map.put(:args, args)
                    |> Map.put(:repo, unquote(repo))
                    |> Map.put(:connection_query, query)

                  {:ok, result}
                end
            end
          end)

          middleware unquote(after_resolve)
        end
      end
    end

    def create_query(query_module, returns, opts) do
      function_name = BoundedContext.__function_name__(query_module, opts)
      query_args = create_query_args(query_module, opts)
      description = query_module.__simple_moduledoc__()
      {before_resolve, after_resolve} = Middleware.middleware(opts)

      quote do
        require Middleware

        field unquote(function_name), unquote(returns) do
          unquote_splicing(query_args)
          description unquote(description)

          middleware unquote(before_resolve)

          resolve(fn parent, args, resolution ->
            opts =
              resolution
              |> Metadata.merge(unquote(opts))
              |> Keyword.put(:tag?, true)
              |> DefaultOpts.set()

            args =
              args
              |> FieldMapping.resolve_parent_mappings(unquote(query_module), parent, args, unquote(opts))
              |> FieldMapping.run_field_transformations(unquote(query_module), unquote(opts))

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

          middleware unquote(after_resolve)
        end
      end
    end

    defp create_query_args(query_module, opts) do
      query_module.__filters__()
      |> FieldMapping.reject_parent_mappings(opts)
      |> Args.extract_args(opts)
      |> Enum.map(fn {name, absinthe_type, required, opts} ->
        case required do
          true -> quote do: arg(unquote(name), non_null(unquote(absinthe_type)), unquote(opts))
          false -> quote do: arg(unquote(name), unquote(absinthe_type), unquote(opts))
        end
      end)
    end
  end
end
