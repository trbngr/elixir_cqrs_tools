if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.InvalidEnumError do
    defexception [:module, :field]

    def message(%{module: module, field: field}) do
      "The field '#{inspect(module)}.#{field}' is not an enum."
    end
  end

  defmodule Cqrs.Absinthe.InvalidSourceError do
    defexception [:module]

    def message(%{module: module}),
      do: "#{inspect(module)} is not a Cqrs.Query, Cqrs.Command, or an Ecto.Schema"
  end

  defmodule Cqrs.Absinthe.InvalidMiddlewareFunction do
    defexception [:module, :position]

    def message(%{module: module, position: position}) do
      "#{inspect(module)} #{position} function should arity 2"
    end
  end

  defmodule Cqrs.Absinthe.MapTypeMappingError do
    defexception [:source, :macro, :type]

    def message(%{source: source, macro: macro, type: type}) do
      example = """
      #{macro} #{source}, :return_type,
      as: :query_name,
      arg_types: [#{IO.ANSI.format([:red, to_string(type), ": :existing_absinthe_type"])}]
      """

      """
      Missing absinthe type for the type #{source}.#{type}.

      Example:
      #{IO.ANSI.format([:blue, example])}
      """
    end
  end

  defmodule Cqrs.Absinthe.EnumTypeMappingError do
    defexception [:source, :macro, :type]

    def message(%{source: source, macro: macro, type: type}) do
      example = """
      #{macro} #{source}, :return_type,
      as: :query_name,
      arg_types: [#{IO.ANSI.format([:red, to_string(type), ": :existing_absinthe_enum_type"])}]
      """

      """
      Missing absinthe enum type for the type #{source}.#{type}.

      Example:
      #{IO.ANSI.format([:blue, example])}
      """
    end
  end

  defmodule Cqrs.Absinthe.Errors do
    @moduledoc false
    def attach_error_handler(opts) do
      {provided_then, opts} = Keyword.pop(opts, :then, &Function.identity/1)
      Keyword.put(opts, :then, &handle_errors(&1, provided_then))
    end

    def handle_errors({:error, {:invalid_command, errors}}, _) do
      errors =
        Enum.flat_map(errors, fn
          {key, messages} -> Enum.map(messages, fn msg -> "#{key} #{msg}" end)
        end)

      {:error, errors}
    end

    def handle_errors(other, then) when is_function(then, 1) do
      then.(other)
    end
  end
end
