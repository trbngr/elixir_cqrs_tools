# Used by "mix format"
locals_without_parens = [
  field: 2,
  field: 3,
  filter: 2,
  filter: 3,
  option: 3,
  command: 1,
  import_commands: 1,
  command: 2,
  binding: 2,
  query: 1,
  query: 2,
  derive_query: 2,
  derive_query: 3,
  derive_event: 1,
  derive_event: 2,
  derive_connection: 3,
  derive_mutation_input: 1,
  derive_mutation_input: 2,
  derive_mutation: 2,
  derive_mutation: 3,
  derive_enum: 3
]

[
  locals_without_parens: locals_without_parens,
  import_deps: [:ecto, :absinthe],
  line_length: 120,
  export: [
    locals_without_parens: locals_without_parens
  ],
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
