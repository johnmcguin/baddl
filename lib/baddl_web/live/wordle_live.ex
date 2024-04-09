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

  def render(assigns) do
    ~H"""
    <div
      :if={String.length(@winner) > 0}
      class={
        if String.length(@winner) > 0 do
          "reveal space-y-4"
        else
          "space-y-4"
        end
      }
    >
      <div class="flex flex-row justify-center items-center">
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="w-6 h-6 text-yellow-500 lightning"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z"
          />
        </svg>
        <h2 class="text-center text-3xl mx-3 uppercase">
          <%= @winner %> Won! (<%= @answer.result %>)
        </h2>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="1.5"
          stroke="currentColor"
          class="w-6 h-6 text-yellow-500 lightning"
          style="animation-delay: 0.9s"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            d="m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z"
          />
        </svg>
      </div>
      <!-- <div class="flex flex-row justify-center items-center"> -->
      <!--
      <%= Enum.with_index(0..5, fn _guess, idx -> %>
        -->
        <!--     <span -->
        <!--       class="reveal result correct w-6 h-6 inline-block mx-0.5" -->
        <!--       style={"animation-delay: #{idx * 0.1}s"} -->
        <!--     > -->
        <!--     </span> -->
        <!--
      <% end) %>
      -->
      <!-- </div> -->
      <.button phx-click="new_game" class="w-full">Start New Game</.button>
    </div>
    <div :if={!@game_ready} class="pulse text-center text-3xl text-gray-500">
      waiting for all players to join...
    </div>
    <.async_result :let={answer} :if={@game_ready && String.length(@winner) == 0} assign={@answer}>
      <:failed :let={_failure}>there was an error creating the game</:failed>
      <div :if={@messages} class="game-meta grid gap-4 grid-cols-2">
        <div :for={{player, summary} <- @messages} class="flex flex-row justify-center mb-4">
          <span class="mr-4"><%= player %>:</span>
          <div>
            <%= Enum.with_index(summary.latest_guess, fn guess, idx -> %>
              <span
                phx-hook="AnimatePlayer"
                id={"#{player}-guess-#{idx}"}
                class={"result #{String.downcase(guess)} w-3 h-3 inline-block"}
                style={"animation-delay: #{idx * 0.1}s"}
              >
              </span>
            <% end) %>
            <span class="mr-4">(attempt <%= summary.latest_guess_num %>)</span>
          </div>
        </div>
      </div>
      <div id="wordle-game" phx-hook="Wordle" phx-update="ignore" data-answer={answer}></div>
    </.async_result>
    """
  end

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
        # |> assign(winner: "")
        |> assign(winner: "John")
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
