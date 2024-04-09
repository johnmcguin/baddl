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

  @topic "game:"

  def handle_params(%{"id" => id, "name" => name}, _url, socket) do
    case Games.get_active_room(id) do
      nil ->
        socket
        |> put_flash(:error, "Game room #{id} not found")
        |> push_navigate(to: "/")
        |> then(fn socket -> {:noreply, socket} end)

      %Room{} = room ->
        Endpoint.subscribe(@topic <> id)
        Presence.track(self(), @topic <> id, name, %{name: name})
        broadcast_readiness(@topic <> id, game_ready?(id, room.num_players))

        socket
        |> assign(name: name)
        |> assign(room_id: id)
        |> assign(messages: %{})
        |> assign(game_ready: false)
        |> assign(winner: "")
        |> assign_async(:answer, fn -> get_answer(id) end)
        |> then(fn socket -> {:noreply, socket} end)
    end
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, push_patch(socket, to: "/game/#{id}?name=Guest")}
  end

  def handle_event("handle_guess", payload, socket) do
    Endpoint.broadcast_from(self(), @topic <> socket.assigns.room_id, "handle_player_guess", %{
      player: socket.assigns.name,
      latest_guess: payload["guessState"],
      latest_guess_num: payload["lastGuess"]
    })

    {:noreply, socket}
  end

  # TODO: update this and the UI to show the player's name, how many guesses it took them, and the answer
  def handle_event("handle_win", _payload, socket) do
    Endpoint.broadcast(@topic <> socket.assigns.room_id, "handle_game_won", %{
      player: socket.assigns.name
    })

    {:noreply, socket}
  end

  def handle_event("new_game", _payload, socket) do
    room_id = socket.assigns.room_id

    case Games.create_new_game(room_id) do
      {:ok, _results} ->
        Endpoint.broadcast(@topic <> room_id, "handle_new_game", %{})
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
        %{topic: @topic <> game_token, event: "handle_new_game", payload: _payload},
        socket
      ) do
    Logger.info("#{__MODULE__} handle_new_game")

    socket
    |> assign(winner: "")
    |> assign_async(:answer, fn -> get_answer(game_token) end)
    |> assign(messages: %{})
    |> then(fn socket -> {:noreply, socket} end)
  end

  def handle_info(
        %{topic: @topic <> game_token, event: "check_readiness", payload: _payload},
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
    Presence.list(@topic <> game_token)
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
end
