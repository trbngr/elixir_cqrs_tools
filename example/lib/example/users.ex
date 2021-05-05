defmodule Example.Users do
  use Cqrs.BoundedContext
  import Cqrs.BoundedContext
  import ExecutionResultHelper

  alias Example.Users
  alias Example.Users.Messages.CreateUser

  defmodule AfterExecution do
    # This is the only thing I don't like right now
    # I'm not sure how to reference a function from the Users module
    # in the import_commands, after: [] so a nested module it is

    def load_user(result) do
      with {:ok, id} <- ExecutionResultHelper.aggregate_id(result) do
        Users.get_user(id: id)
      end
    end
  end

  query Example.Queries.GetUser
  query Example.Queries.ListUsers

  command CreateUser, after: &AfterExecution.load_user/1

  import_commands Example.Users.Router,
    except: [CreateUser],
    after: [
      reinstate_user: &AfterExecution.load_user/1,
      suspend_user: &AfterExecution.load_user/1
    ]
end
