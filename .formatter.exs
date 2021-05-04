# Used by "mix format"
[
  locals_without_parens: [
    field: 2,
    field: 3,
    filter: 2,
    filter: 3,
    command: 1,
    command: 2,
    query: 1,
    query: 2,
    derive_event: 1,
    derive_event: 2
  ],
  import_deps: [:ecto],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
