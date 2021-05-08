# 1. Example

Application to showcase the [`cqrs_tools`](https://github.com/trbngr/elixir_cqrs_tools) library for Elixir.

## 1.1. Launch the app

```bash
mix deps.get
iex -S mix phx.server
```

Launch GraphiQL with this [link](http://localhost:4000/graphiql?query=mutation%20create(%24user%3A%20CreateUserInput!)%20%7B%0A%20%20createUser(input%3A%20%24user)%20%7B%0A%20%20%20%20...UserData%0A%20%20%7D%0A%7D%0A%0Aquery%20users%20%7B%0A%20%20users(first%3A%205%2C%20status%3A%20ACTIVE)%20%7B%0A%20%20%20%20edges%20%7B%0A%20%20%20%20%20%20node%20%7B%0A%20%20%20%20%20%20%20%20...UserData%0A%20%20%20%20%20%20%7D%0A%20%20%20%20%7D%0A%20%20%7D%0A%7D%0A%0Aquery%20user_by_id(%24userId%3A%20ID!)%20%7B%0A%20%20user(id%3A%20%24userId)%20%7B%0A%20%20%20%20...UserData%0A%20%20%7D%0A%7D%0A%0Aquery%20user_by_email(%24userEmail%3A%20String!)%20%7B%0A%20%20user(email%3A%20%24userEmail)%20%7B%0A%20%20%20%20...UserData%0A%20%20%7D%0A%7D%0A%0Amutation%20suspend(%24userId%3A%20ID!)%20%7B%0A%20%20suspendUser(id%3A%20%24userId)%20%7B%0A%20%20%20%20...UserData%0A%20%20%7D%0A%7D%0A%0Amutation%20reinstate(%24userId%3A%20ID!)%20%7B%0A%20%20reinstateUser(id%3A%20%24userId)%20%7B%0A%20%20%20%20...UserData%0A%20%20%7D%0A%7D%0A%0Afragment%20UserData%20on%20User%20%7B%0A%20%20id%0A%20%20name%0A%20%20email%0A%20%20status%0A%7D%0A&variables=%7B%0A%20%20%22user%22%3A%20%7B%0A%20%20%20%20%22email%22%3A%20%22chris%40example.com%22%2C%0A%20%20%20%20%22name%22%3A%20%22chris%22%0A%20%20%7D%2C%0A%20%20%22userId%22%3A%20%22052c1984-74c9-522f-858f-f04f1d4cc786%22%2C%0A%20%20%22userEmail%22%3A%20%22chris%40example.com%22%0A%7D).


_this application uses :ets for data persistence so any data you enter will be discarded when you stop the app_
