defmodule Baddl.Games.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @chars ~c"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :short_token, :string
    field :ended_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def unique_enough() do
    for _ <- 1..5, into: "", do: <<Enum.random(@chars)>>
  end

  @doc false
  def create(room, attrs) do
    room
    |> cast(attrs, [:short_token])
    |> validate_required([:short_token])
  end
end
