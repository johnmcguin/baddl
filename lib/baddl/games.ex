defmodule Baddl.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Baddl.Repo
  alias Baddl.Games.{Room, Game}

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
  Gets one active room with short_token

  Returns nil if no active room


  ## Examples

      iex> get_active_room("293jskdj")
      %Room{}

      iex> get_active_room("invalid")
      nil
  """
  def get_active_room(short_token) do
    query_active_room(short_token)
    |> Repo.one()
  end

  @doc """
  Returns the answer for the active game


  ## Examples

      iex> get_answer_for_current_game("293jskdj")
      "answer"

      iex> get_answer_for_current_game("invalid")
      nil
  """
  def get_answer_for_current_game(short_token) do
    query_active_room(short_token)
    |> join(:inner, [r], g in assoc(r, :games))
    |> where([r, g], is_nil(g.ended_at))
    |> select([r, g], g.answer)
    |> Repo.one()
  end

  defp query_active_room(short_token) do
    Room
    |> where([r], is_nil(r.ended_at) and r.short_token == ^short_token)
  end

  @doc """
  Closes the active room by short_token identifier

  ## Examples

      iex> close_room("293jskdj")
      {:ok, %{room: room, close_room: close_room}}

      iex> close_room("sadpath")
      {:error, errors}
  """
  def close_room(short_token) do
    Multi.new()
    |> Multi.one(:room, query_active_room(short_token))
    |> Multi.update(:close_room, &Room.close_room(&1.room))
    |> Repo.transaction()
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
