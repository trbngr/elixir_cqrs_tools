if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Mutation do
    alias Cqrs.{BoundedContext, Absinthe.Mutation}

    defmacro derive_mutation_input(command_module, opts \\ []) do
      input =
        quote do
          Mutation.__create_input_object__(
            unquote(command_module),
            unquote(opts)
          )
        end

      Module.eval_quoted(__CALLER__, input)
    end

    def __create_input_object__(command_module, opts) do
      function_name = BoundedContext.__function_name__(command_module, opts)
      input_object_fields = __create_input_object_fields__(command_module, opts)

      quote do
        input_object unquote(:"#{function_name}_input") do
          (unquote_splicing(input_object_fields))
        end
      end
    end

    def __create_input_object_fields__(command_module, opts) do
      opts = Keyword.merge(opts, source: command_module, macro: :derive_mutation_input)

      command_module.__fields__()
      |> Cqrs.Absinthe.__extract_fields__(opts)
      |> Enum.map(fn {name, absinthe_type, required} ->
        case required do
          true -> quote do: field(unquote(name), non_null(unquote(absinthe_type)))
          false -> quote do: field(unquote(name), unquote(absinthe_type))
        end
      end)
    end

    defmacro derive_mutation(command_module, returns, opts \\ []) do
      mutation =
        quote do
          Mutation.__create_mutatation__(
            unquote(command_module),
            unquote(returns),
            unquote(opts)
          )
        end

      Module.eval_quoted(__CALLER__, mutation)
    end

    def __create_mutatation__(command_module, returns, opts) do
      function_name = BoundedContext.__function_name__(command_module, opts)
      args = __create_mutatation_args__(command_module, function_name, opts)

      quote do
        field unquote(function_name), unquote(returns) do
          unquote_splicing(args)

          resolve(fn args, _res ->
            attrs = Map.get(args, :input, args)
            BoundedContext.__dispatch_command__(unquote(command_module), attrs, unquote(opts))
          end)
        end
      end
    end

    defp __create_mutatation_args__(command_module, function_name, opts) do
      case Keyword.get(opts, :input_object?, true) do
        true ->
          args =
            quote do
              arg(:input, unquote(:"#{function_name}_input"))
            end

          [args]

        false ->
          __create_mutation_args__(command_module, opts)
      end
    end

    def __create_mutation_args__(command_module, opts) do
      opts = Keyword.merge(opts, source: command_module, macro: :derive_mutation)

      command_module.__fields__()
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
