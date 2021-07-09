if Code.ensure_loaded?(Absinthe) do
  alias Cqrs.Absinthe.Args

  defmodule Cqrs.Absinthe.Object do
    def create_object(object_name, source_module, opts \\ []) do
      fields = fields(source_module, opts)

      case Keyword.get(opts, :input?, false) do
        true ->
          quote do
            input_object unquote(object_name) do
              (unquote_splicing(fields))
            end
          end

        false ->
          quote do
            object unquote(object_name) do
              (unquote_splicing(fields))
            end
          end
      end
    end

    defp fields(source_module, opts) do
      case Keyword.get(opts, :input?, false) do
        false ->
          source_module.__fields__()
          |> Args.extract_args(opts)
          |> Enum.map(fn {name, absinthe_type, _required, opts} ->
            quote do: field(unquote(name), unquote(absinthe_type), unquote(opts))
          end)

        true ->
          source_module.__fields__()
          |> Args.extract_args(opts)
          |> Enum.map(fn {name, absinthe_type, required, opts} ->
            case required do
              true -> quote do: field(unquote(name), non_null(unquote(absinthe_type)), unquote(opts))
              false -> quote do: field(unquote(name), unquote(absinthe_type), unquote(opts))
            end
          end)
      end
    end
  end
end
