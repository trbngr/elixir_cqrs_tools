defmodule ChangeWidgetStatus do
  use Cqrs.Command

  field :status, :enum, values: [:new, :old]

  @impl true
  def handle_dispatch(command, _opts) do
    {:ok, command}
  end
end

defmodule WidgetTypes do
  use Cqrs.Absinthe

  derive_enum :widget_status, ChangeWidgetStatus, :status

  object :widget do
    field :status, :widget_status
  end
end

defmodule AbsintheSchema do
  use Absinthe.Schema

  import_types WidgetTypes

  query do
  end
end
