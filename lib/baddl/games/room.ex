defmodule Baddl.Games.Room do
  use Ecto.Schema
  import Ecto.Changeset
  alias Baddl.Games.Game

  @chars ~c"0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
  @short_token_len 8

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "rooms" do
    field :short_token, :string
    field :num_players, :integer
    field :ended_at, :utc_datetime

    has_many :games, Game

    timestamps(type: :utc_datetime)
  end

  def unique_enough() do
    for _ <- 1..@short_token_len, into: "", do: <<Enum.random(@chars)>>
  end

  @doc false
  def create(params) do
    %__MODULE__{}
    |> cast(params, [:num_players])
    |> validate_required([:num_players])
    |> validate_number(:num_players, greater_than: 0)
    |> put_change(:short_token, unique_enough())
  end

  @doc false
  def create_with_answer(params) do
    %__MODULE__{}
    |> cast(params, [:num_players])
    |> cast_assoc(:games)
    |> validate_required([:num_players])
    |> validate_number(:num_players, greater_than: 0)
    |> put_change(:short_token, unique_enough())
  end

  def close_room(room) do
    room
    |> change(%{ended_at: DateTime.truncate(DateTime.utc_now(), :second)})
  end

  @doc false
  def changeset_for_create(params) do
    types = %{display_name: :string, num_players: :integer}

    {%{}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:display_name])
  end

  @doc false
  def changeset_for_join(params, present_names \\ []) do
    types = %{room_id: :string, display_name: :string}

    {%{}, types}
    |> cast(params, Map.keys(types))
    |> validate_required([:room_id, :display_name])
    |> validate_length(:room_id, is: @short_token_len)
    |> validate_unique_name(:display_name, present_names)
  end

  defp validate_unique_name(changeset, field, values) do
    validate_change(changeset, field, fn _f, value ->
      case Enum.any?(values, fn v -> v == value end) do
        true ->
          [{field, "#{value} is already in the game room. Please choose another name."}]

        false ->
          []
      end
    end)
  end
end
