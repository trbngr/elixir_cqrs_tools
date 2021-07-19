defmodule Cqrs.Options do
  @moduledoc false
  def tag_option do
    {:tag?,
     [
       type: :boolean,
       default: false,
       doc: "If `true`, the result will be tagged with an `:ok` or `:error` tuple."
     ]}
  end

  def metadata_option do
    {:metadata,
     [
       type: :any,
       default: %{},
       doc: "Metadata defined by the `:cqrs_tools, :metadata` configuration."
     ]}
  end

  defmacro defaults do
    quote do
      Enum.map(@options, fn {name, opts} ->
        {name, Keyword.get(opts, :default)}
      end)
    end
  end

  @doc """
  Describes a supported option for this command.

  ## Options
  * `:default` - this default value if the option is not provided.
  * `:description` - The documentation for this option.
  """
  @spec option(name :: atom(), type :: any(), keyword()) :: any()
  defmacro option(name, type, opts) when is_atom(name) and is_list(opts) do
    quote do
      {docs, opts} = Keyword.pop(unquote(opts), :description)

      valid_opts = [:required, :default, :keys, :deprecated, :rename_to, :doc, :subsection]

      opts =
        opts
        |> Keyword.put_new(:default, nil)
        |> Keyword.update(:doc, docs || "", &Function.identity/1)
        |> Keyword.take(valid_opts)

      type = [type: unquote(type)]
      @options {unquote(name), Keyword.merge(type, opts)}
    end
  end

  def normalize(%{} = options), do: Map.to_list(options)
  def normalize(options) when is_list(options), do: options

  def validate_opts(mod, opts) do
    schema = mod.__options_schema__()
    defined_opts = Keyword.keys(schema)
    opts_to_validate = Keyword.take(opts, defined_opts)

    case NimbleOptions.validate(opts_to_validate, schema) do
      {:ok, _} -> {:ok, opts}
      {:error, error} -> {:error, error}
    end
  end
end
