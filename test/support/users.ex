defmodule Users do
  use Cqrs.BoundedContext

  command CreateUser
  command CreateUser, as: :create_user2

  query GetUser
  query GetUser, as: :get_user2
end
