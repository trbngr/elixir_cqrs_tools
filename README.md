# CqrsTools

A collection of handy Elixir macros for CQRS applications. 

This library was the stomping grounds for the set of libraries that live on as [Blunt](https://github.com/blunt-elixir/blunt).

The new libs are not feature complete, but will be soon.

# Playground

Clone this repo, make sure `docker` is running and run this:

```shell
docker run -p 8080:8080 -u $(id -u):$(id -g) -v $(pwd)/livebooks:/data livebook/livebook
```

A URL will be presented. Open it in your browser.

# Docs

Documentation can be found at [hexdocs](https://hexdocs.pm/cqrs_tools).

# Example App

There is an example Commanded app in the [example](example) directory.
