defmodule BaddlWeb.WordleLive do
  @moduledoc """
  Wordle LiveView

  Renders the wordle elm app.
  Shows the current game status realtime (reporting on each player status)
  """
  use BaddlWeb, :live_view

  require Logger

  alias BaddlWeb.Endpoint
  alias BaddlWeb.Presence
  alias Baddl.Games.Room
  alias Baddl.Games

  @current_game "game:"
  @all_players "all_players"

  def handle_params(%{"id" => id, "name" => name}, _url, socket) do
    case Games.get_active_room(id) do
      nil ->
        socket
        |> put_flash(:error, "Game room #{id} not found")
        |> push_navigate(to: "/")
        |> then(fn socket -> {:noreply, socket} end)

      %Room{} = room ->
        Endpoint.subscribe(@current_game <> id)
        Presence.track(self(), @current_game <> id, name, %{name: name})
        Presence.track(self(), @all_players, "game_" <> id <> "_" <> name, %{name: name})
        broadcast_readiness(@current_game <> id, game_ready?(id, room.num_players))

        socket
        |> assign(name: name)
        |> assign(room_id: id)
        |> assign(game_id: get_game_id(room))
        |> assign(messages: %{})
        |> assign(game_ready: false)
        |> assign(winner: get_game_winner(room))
        |> assign_async(:answer, fn -> get_answer(id) end)
        |> then(fn socket -> {:noreply, socket} end)
    end
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, push_patch(socket, to: "/game/#{id}?name=Guest")}
  end

  def handle_event("handle_guess", payload, socket) do
    Endpoint.broadcast_from(
      self(),
      @current_game <> socket.assigns.room_id,
      "handle_player_guess",
      %{
        player: socket.assigns.name,
        latest_guess: payload["guessState"],
        latest_guess_num: payload["lastGuess"]
      }
    )

    {:noreply, socket}
  end

  def handle_event("handle_win", _payload, socket) do
    Endpoint.broadcast(@current_game <> socket.assigns.room_id, "handle_game_won", %{
      player: socket.assigns.name
    })

    Games.end_game(socket.assigns.game_id, socket.assigns.name)

    {:noreply, socket}
  end

  def handle_event("new_game", _payload, socket) do
    room_id = socket.assigns.room_id

    case Games.create_new_game(room_id) do
      {:ok, _results} ->
        Endpoint.broadcast(@current_game <> room_id, "handle_new_game", %{})
        {:noreply, socket}

      {:error, _errors} ->
        socket
        |> put_flash(:error, "Failed to start a new game. Please create a new game room.")
        |> push_navigate(to: "/")
        |> then(fn socket -> {:noreply, socket} end)
    end

    {:noreply, socket}
  end

  def handle_info(
        %{topic: @current_game <> game_token, event: "handle_new_game", payload: _payload},
        socket
      ) do
    Logger.info("#{__MODULE__} handle_new_game")
    case Games.get_active_room(game_token) do
      nil ->
        socket
        |> put_flash(:error, "Game room #{game_token} not found")
        |> push_navigate(to: "/")
        |> then(fn socket -> {:noreply, socket} end)

      %Room{} = room ->
        socket
        |> assign(game_id: get_game_id(room))
        |> assign(messages: %{})
        |> assign(winner: get_game_winner(room))
        |> assign_async(:answer, fn -> get_answer(game_token) end)
        |> then(fn socket -> {:noreply, socket} end)
    end
  end

  def handle_info(
        %{topic: @current_game <> game_token, event: "check_readiness", payload: _payload},
        socket
      ) do
    Logger.info("#{__MODULE__} check_readiness")
    room = Games.get_active_room(game_token)

    {:noreply, assign(socket, game_ready: game_ready?(game_token, room.num_players))}
  end

  def handle_info(%{topic: _topic, event: "handle_readiness", payload: payload}, socket) do
    Logger.info("#{__MODULE__} handle_readiness")
    {:noreply, assign(socket, game_ready: payload.ready)}
  end

  def handle_info(%{topic: _topic, event: "handle_set_answer", payload: payload}, socket) do
    Logger.info("#{__MODULE__} handle_set_answer")

    if socket.assigns.answer do
      {:noreply, socket}
    else
      {:noreply, assign(socket, answer: payload)}
    end
  end

  def handle_info(%{topic: _topic, event: "handle_player_guess", payload: payload}, socket) do
    Logger.info("#{__MODULE__} handle_player_guess")

    socket
    |> update_player_state(payload)
    |> push_event("animate-player", %{player: payload.player})
    |> then(fn socket -> {:noreply, socket} end)
  end

  def handle_info(%{topic: _topic, event: "handle_game_won", payload: payload}, socket) do
    Logger.info("#{__MODULE__} handle_game_won")
    
    socket
    |> assign(winner: payload.player)
    |> then(fn socket -> {:noreply, socket} end)
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp get_answer(room_id) do
    case Games.get_answer_for_current_game(room_id) do
      nil ->
        Logger.error("#{__MODULE__} failed to get answer")
        {:error, "could not get the answer for the current game"}

      answer ->
        {:ok, %{answer: answer}}
    end
  end

  defp broadcast_readiness(topic, ready_state) do
    Endpoint.broadcast(topic, "handle_readiness", %{ready: ready_state})
  end

  defp game_ready?(game_token, expected_players) do
    Presence.list(@current_game <> game_token)
    |> Map.keys()
    |> Kernel.length()
    |> Kernel.==(expected_players)
  end

  defp update_player_state(socket, %{
         player: player,
         latest_guess: latest_guess,
         latest_guess_num: latest_guess_num
       }) do
    socket
    |> update(:messages, fn messages ->
      new_player_state =
        Map.put(%{}, player, %{
          latest_guess: latest_guess,
          latest_guess_num: latest_guess_num
        })

      Map.merge(messages, new_player_state)
    end)
  end

  defp get_game_id(%Room{games: games} = _room) do
    case List.first(games) do
      nil ->
        "initial"

      game ->
        game.id
    end
  end

  defp get_game_winner(%Room{games: games} = _room) do
    case List.first(games) do
      nil ->
        ""

      game ->
        winner = Map.get(game, :won_by)
        winner || ""
    end
  end
end
