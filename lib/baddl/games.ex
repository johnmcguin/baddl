defmodule Baddl.Games do
  @moduledoc """
  The Games context.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi

  alias Baddl.Repo
  alias Baddl.Games.{Room, Game, Word}

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
    |> room_active_game()
    |> preload([r, g], games: g)
    |> Repo.one()
  end

  @doc """
  Creates a new game for a given room

  ## Examples

      iex> create_new_game("293jskdj")
      {:ok, _multi_results}

      iex> create_new_game("invalid")
      {:error, _multi_errors}
  """
  def create_new_game(short_token) do
    Multi.new()
    |> Multi.one(:room, query_active_room(short_token))
    |> Multi.run(:game, fn _repo, %{room: room} ->
      case room do
        nil ->
          {:error, :not_found}

        room ->
          Game.new_game(%Game{}, %{answer: get_random_word(), room_id: room.id})
          |> Repo.insert()
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Ends a game with a winner. Persists end game state to handle refresh or 
  reconnection

  ## Examples

      iex> end_game("192398-289209243-190293", "winner")
      {:ok, _multi_results}

      iex> end_game("not_found_id", "winner")
      {:error, _multi_errors}
  """
  def end_game(game_id, winner) do
    get_game =
      Game
      |> where([g], g.id == ^game_id)

    Multi.new()
    |> Multi.one(:game, get_game)
    |> Multi.run(:end_game, fn _repo, %{game: game} ->
      case game do
        nil ->
          {:error, :not_found}

        game ->
          Game.end_game(game, %{won_by: winner})
          |> Repo.update()
      end
    end)
    |> Repo.transaction()
  end

  @doc """
  Fetches a random word to create a game with


  ## Examples

      iex> get_random_word()
      "place"

      iex> get_active_room()
      nil
  """
  def get_random_word() do
    Word
    |> order_by(fragment("RANDOM()"))
    |> limit(1)
    |> select([w], w.word)
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
    |> room_active_game()
    |> select([r, g], g.answer)
    |> Repo.one()
  end

  def room_active_game(room_query) do
    room_query
    |> join(:left, [r], g in assoc(r, :games))
    |> order_by([r, g], desc: g.inserted_at)
    |> first()
  end

  def query_active_room(short_token) do
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
