defmodule Persona do
  use Cqrs.ValueObject

  field :name, :string
  field :dob, :date
end

defmodule ChangeWidgetStatus do
  use Cqrs.Command

  field :status, :enum, values: [:new, :old]
  field :persona, Persona

  @impl true
  def handle_dispatch(command, _opts) do
    {:ok, command}
  end
end

defmodule WidgetTypes do
  use Cqrs.Absinthe

  derive_enum :widget_status, ChangeWidgetStatus, :status
  derive_input_object :persona_input, Persona

  object :widget do
    field :status, :widget_status
  end

  object :widget_mutations do
    derive_mutation ChangeWidgetStatus, :widget,
      arg_types: [
        status: :widget_status,
        persona: :persona_input
      ]
  end
end

defmodule AbsintheSchema do
  use Absinthe.Schema

  import_types WidgetTypes
  import_types Absinthe.Type.Custom

  query do
  end

  mutation do
    import_fields :widget_mutations
  end
end
