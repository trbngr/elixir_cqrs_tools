if Code.ensure_loaded?(Absinthe) do
  defmodule Cqrs.Absinthe.FieldMapping do
    @moduledoc false

    require Logger

    def reject_parent_mappings(fields, opts) do
      field_mappings = Keyword.get(opts, :parent_mappings, []) |> Keyword.keys()
      Enum.reject(fields, fn {field, _, _} -> Enum.member?(field_mappings, field) end)
    end

    def resolve_parent_mappings(attrs, module, parent, opts) do
      field_mappings = Keyword.get(opts, :parent_mappings, [])

      Enum.reduce(field_mappings, attrs, fn
        {field_name, resolver_fun}, acc when is_function(resolver_fun, 1) ->
          Map.put(acc, field_name, resolver_fun.(parent))

        {field_name, _resolver_fun}, acc ->
          Logger.warn(
            "#{inspect(module)} - Invalid Field Mapping for #{field_name}. Expected a function with an arity of 1"
          )

          acc
      end)
    end

    def run_field_transformations(attrs, module, opts) do
      field_transformations = Keyword.get(opts, :field_transforms, []) ++ Keyword.get(opts, :filter_transforms, [])

      Enum.reduce(field_transformations, attrs, fn
        {field_name, transform_fun}, acc when is_function(transform_fun, 1) ->
          Map.update(acc, field_name, nil, transform_fun)

        {field_name, _transform_fun}, acc ->
          Logger.warn(
            "#{inspect(module)} - Invalid Field Transformation for #{field_name}. Expected a function with an arity of 1"
          )

          acc
      end)
    end
  end
end
