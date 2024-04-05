defmodule Baddl.Games.Room do
  use Ecto.Schema
  import Ecto.Changeset

  @chars ~c"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @short_token_len 8

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :short_token, :string
    field :num_players, :integer
    field :ended_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  def unique_enough() do
    for _ <- 1..@short_token_len, into: "", do: <<Enum.random(@chars)>>
  end

  @doc false
  def create(params) do
    %__MODULE__{}
    |> Ecto.Changeset.cast(params, [:num_players])
    |> Ecto.Changeset.validate_required([:num_players])
    |> Ecto.Changeset.validate_number(:num_players, greater_than: 0)
    |> put_change(:short_token, unique_enough())
  end

  @doc false
  def changeset_for_create(params) do
    types = %{display_name: :string, num_players: :integer}

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:display_name])
  end

  @doc false
  def changeset_for_join(params) do
    types = %{room_id: :string, display_name: :string}

    {%{}, types}
    |> Ecto.Changeset.cast(params, Map.keys(types))
    |> Ecto.Changeset.validate_required([:room_id, :display_name])
    |> Ecto.Changeset.validate_length(:room_id, is: @short_token_len)
  end
end
