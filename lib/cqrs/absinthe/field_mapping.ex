if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.FieldMapping do
    @moduledoc false

    require Logger

    def reject_parent_mappings(fields, opts) do
      field_mappings = Keyword.get(opts, :parent_mappings, []) |> Keyword.keys()
      Enum.reject(fields, fn {field, _, _} -> Enum.member?(field_mappings, field) end)
    end

    def resolve_parent_mappings(attrs, module, parent, args, opts) do
      field_mappings = Keyword.get(opts, :parent_mappings, [])

      Enum.reduce(field_mappings, attrs, fn
        {field_name, resolver_fun}, acc when is_function(resolver_fun, 1) ->
          value = resolver_fun.(parent)
          Logger.debug("[cqrs_tools] Resolved #{inspect(module)}.#{field_name} from parent: #{inspect(value)}")
          Map.put(acc, field_name, value)

        {field_name, resolver_fun}, acc when is_function(resolver_fun, 2) ->
          value = resolver_fun.(parent, args)
          Logger.debug("[cqrs_tools] Resolved #{inspect(module)}.#{field_name} from parent: #{inspect(value)}")
          Map.put(acc, field_name, value)

        {field_name, _resolver_fun}, acc ->
          Logger.warn(
            "[cqrs_tools] Invalid Field Mapping for #{inspect(module)}.#{field_name}. Expected a function with an arity of 1 or 2"
          )

          acc
      end)
    end

    def run_field_transformations(attrs, module, opts) do
      field_transformations = Keyword.get(opts, :field_transforms, []) ++ Keyword.get(opts, :filter_transforms, [])

      Enum.reduce(field_transformations, attrs, fn
        {field_name, transform_fun}, acc when is_function(transform_fun, 1) ->
          Map.update(acc, field_name, nil, fn source ->
            transformed = transform_fun.(source)

            Logger.debug(
              "[cqrs_tools] Transformed #{inspect(module)}.#{field_name}: #{inspect(source)} -> #{inspect(transformed)}"
            )

            transformed
          end)

        {field_name, _transform_fun}, acc ->
          Logger.warn(
            "[cqrs_tools] Invalid Field Transformation for #{inspect(module)}.#{field_name}. Expected a function with an arity of 1"
          )

          acc
      end)
    end
  end
end
