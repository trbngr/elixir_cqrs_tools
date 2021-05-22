if Code.ensure_loaded?(Commanded) do
  defmodule Cqrs.BoundedContext.Commanded do
    @moduledoc """
    If you are a `Commanded` user, you have already registered your commands with your commanded routers.
    Instead of repeating yourself, you can cut down on boilerplate with the `import_commands/1` macro.

        defmodule Users do
          use Cqrs.BoundedContext
          use Cqrs.BoundedContext.Commanded

          import_commands CommandedRouter

          query GetUser
        end
    """

    alias Cqrs.{BoundedContext, Guards}

    defmacro __using__(_) do
      quote do
        import Cqrs.BoundedContext.Commanded, only: :macros
      end
    end

    @doc """
    Imports all of a [Command Router's](`Commanded.Commands.Router`) registered commands.

    ## Options

    * `:only` - Restrict importing to only the commands listed
    * `:except` - Imports commands except those listed
    * `:after` - a list of function names and a function of one arity to run with the execution result

    ### Example
        import_commands Example.Users.Router,
          except: [CreateUser],
          after: [
            reinstate_user: &AfterExecution.load_user/1,
            suspend_user: &AfterExecution.load_user/1
          ]
    """
    defmacro import_commands(router, opts \\ []) do
      opts = Macro.escape(opts)

      quote do
        Guards.ensure_is_commanded_router!(unquote(router))

        only = Keyword.get(unquote(opts), :only, [])
        except = Keyword.get(unquote(opts), :except, [])

        commands = unquote(router).__registered_commands__()

        commands =
          case {only, except} do
            {[], []} -> commands
            {[], except} -> Enum.reject(commands, &Enum.member?(except, &1))
            {only, []} -> Enum.filter(commands, &Enum.member?(only, &1))
            _ -> raise "You can only specify :only or :except"
          end

        Enum.map(commands, fn module -> BoundedContext.command(module, unquote(opts)) end)
      end
    end
  end
end
