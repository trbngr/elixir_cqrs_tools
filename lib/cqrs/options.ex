defmodule Cqrs.Options do
  def tag_option do
    {:tag?, :boolean,
     [
       default: false,
       description:
         "If `true`, the result of the query will be tagged with an `:ok` or `:error` tuple."
     ]}
  end

  def bang_option do
    {:bang?, :boolean, [default: false]}
  end

  defmacro defaults do
    quote do
      Enum.map(@options, fn {name, _hint, opts} ->
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

  @spec option(name :: atom(), {:enum, possible_values :: list()}, keyword()) :: any()
  defmacro option(name, {:enum, possible_values}, opts)
           when is_atom(name) and is_list(opts) and is_list(possible_values) do
    quote do
      opts = Keyword.put_new(unquote(opts), :default, nil)
      @options {unquote(name), {:enum, unquote(possible_values)}, opts}
    end
  end

  @spec option(name :: atom(), hint :: atom(), keyword()) :: any()
  defmacro option(name, hint, opts) when is_atom(name) and is_list(opts) do
    quote do
      opts = Keyword.put_new(unquote(opts), :default, nil)
      @options {unquote(name), unquote(hint), opts}
    end
  end
end
