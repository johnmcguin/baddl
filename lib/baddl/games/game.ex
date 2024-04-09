defmodule Baddl.Games.Game do
  use Ecto.Schema
  import Ecto.Changeset
  alias Baddl.Games.Room

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "games" do
    field :answer, :string
    belongs_to :room, Room

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
end
