defmodule Baddl.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias Baddl.Games.Room

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :answer, :string
    belongs_to :room, Room

    field :ended_at, :utc_datetime
    field :won_by, :string
    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:answer])
    |> validate_required([:answer])
  end

  def new_game(game, attrs) do
    game
    |> cast(attrs, [:answer, :room_id])
    |> validate_required([:answer, :room_id])
  end

  def end_game(game, attrs) do
    game
    |> cast(attrs, [:won_by])
    |> validate_required([:won_by])
    |> change(%{ended_at: DateTime.truncate(DateTime.utc_now(), :second)})
  end
end
