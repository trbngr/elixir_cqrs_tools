defmodule Example.Application do
  use Application

  def start(_type, _opts) do
    children = [Example.Repo, Example.App, Example.ReadModel]
    Supervisor.start_link(children, strategy: :one_for_one, name: Example.Supervisor)
  end
end
