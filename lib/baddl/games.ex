defmodule Baddl.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Baddl.Repo

  alias Baddl.Games.Room

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room!(123)
      %Room{}

      iex> get_room!(456)
      ** (Ecto.NoResultsError)

  """
  def get_room!(id), do: Repo.get!(Room, id)

  @doc """
  Gets a single room.

  Raises `Ecto.NoResultsError` if the Room does not exist.

  ## Examples

      iex> get_room_by(short_token: "293jskdj")
      %Room{}

      iex> get_room_by(short_token: "invalid")
      nil

  """
  def get_room_by(by_query), do: Repo.get_by(Room, by_query)

  @doc """
  Creates a room.

  ## Examples

      iex> create_room()
      {:ok, %Room{}}

  """
  def create_room() do
    Room.create()
    |> Repo.insert()
  end

  @doc """
  Deletes a room.

  ## Examples

      iex> delete_room(room)
      {:ok, %Room{}}

      iex> delete_room(room)
      {:error, %Ecto.Changeset{}}

  """
  def delete_room(%Room{} = room) do
    Repo.delete(room)
  end
end
