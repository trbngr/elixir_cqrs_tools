if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.Mutation do
    @moduledoc false
    alias Cqrs.{
      BoundedContext,
      Absinthe.Args,
      Absinthe.Metadata,
      Absinthe.Errors,
      Absinthe.Middleware,
      Absinthe.FieldMapping
    }

    def create_input_object(command_module, opts) do
      function_name = BoundedContext.__function_name__(command_module, opts)
      input_object_fields = create_input_object_fields(command_module, opts)

      quote do
        input_object unquote(:"#{function_name}_input") do
          (unquote_splicing(input_object_fields))
        end
      end
    end

    defp create_input_object_fields(command_module, opts) do
      command_module.__fields__()
      |> Args.extract_args(opts)
      |> Enum.map(fn {name, absinthe_type, required, opts} ->
        case required do
          true -> quote do: field(unquote(name), non_null(unquote(absinthe_type)), unquote(opts))
          false -> quote do: field(unquote(name), unquote(absinthe_type), unquote(opts))
        end
      end)
    end

    def create_mutatation(command_module, returns, opts) do
      function_name = BoundedContext.__function_name__(command_module, opts)
      args = create_mutatation_args(command_module, function_name, opts)
      description = command_module.__simple_moduledoc__()

      quote do
        require Middleware

        field unquote(function_name), unquote(returns) do
          unquote_splicing(args)
          description unquote(description)

          Middleware.before_resolve(unquote(command_module), unquote(opts))

          resolve(fn parent, args, resolution ->
            attrs =
              args
              |> Map.get(:input, args)
              |> FieldMapping.resolve_parent_mappings(unquote(command_module), parent, args, unquote(opts))
              |> FieldMapping.run_field_transformations(unquote(command_module), unquote(opts))

            opts =
              resolution
              |> Metadata.merge(unquote(opts))
              |> Errors.attach_error_handler()

            BoundedContext.__dispatch_command__(unquote(command_module), attrs, opts)
          end)

          Middleware.after_resolve(unquote(command_module), unquote(opts))
        end
      end
    end

    defp create_mutatation_args(command_module, function_name, opts) do
      if Keyword.get(opts, :input_object?, false) do
        args =
          quote do
            arg(:input, unquote(:"#{function_name}_input"))
          end

        [args]
      else
        create_mutatation_args(command_module, opts)
      end
    end

    defp create_mutatation_args(command_module, opts) do
      command_module.__fields__()
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
