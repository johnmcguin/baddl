defmodule BaddlWeb.WordleLive do
  @moduledoc """
  Wordle LiveView

  Renders the wordle elm app.
  Shows the current game status realtime (reporting on each player status)
  """
  use BaddlWeb, :live_view
  alias BaddlWeb.Endpoint
  alias BaddlWeb.Presence
  alias Baddl.Games.Room
  alias Baddl.Games
  alias Baddl.GameRegistry

  def render(assigns) do
    ~H"""
    <div :if={!@game_ready} class="pulse text-center text-3xl text-gray-500">
      waiting for all players to join...
    </div>
    <.async_result :let={answer} :if={@game_ready} assign={@answer}>
      <:failed :let={_failure}>there was an error creating the game</:failed>
      <div :if={@messages} class="game-meta grid gap-4 grid-cols-2">
        <div :for={{player, summary} <- @messages} class="flex flex-row justify-center mb-4">
          <span class="mr-4"><%= player %>:</span>
          <div>
            <%= Enum.with_index(summary.latest_guess, fn guess, idx -> %>
              <span
                phx-hook="AnimatePlayer"
                id={"#{player}-guess-#{idx}"}
                class={"show #{String.downcase(guess)} w-3 h-3 inline-block"}
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
        Endpoint.subscribe("game:#{id}")
        Presence.track(self(), "game:#{id}", name, %{name: name})
        broadcast_readiness("game:#{id}", game_ready?(id, room.num_players))
        GameRegistry.merge(id, %{expected_players: room.num_players})

        socket
        |> assign(name: name)
        |> assign(room_id: id)
        |> assign(messages: %{})
        |> assign(game_ready: false)
        |> assign_async(:answer, fn -> get_answer(id) end)
        |> then(fn socket -> {:noreply, socket} end)
    end
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, push_patch(socket, to: "/game/#{id}?name=Guest")}
  end

  def handle_event("handle_guess", payload, socket) do
    Endpoint.broadcast_from(self(), "game:#{socket.assigns.room_id}", "handle_player_guess", %{
      player: socket.assigns.name,
      latest_guess: payload["guessState"],
      latest_guess_num: payload["lastGuess"]
    })

    {:noreply, socket}
  end

  # handles info broadcast from other LiveViews
  def handle_info(%{topic: _topic, event: "handle_player_guess", payload: payload}, socket) do
    socket
    |> update_player_state(payload)
    |> push_event("animate-player", %{player: payload.player})
    |> then(fn socket -> {:noreply, socket} end)
  end

  def handle_info(%{topic: _topic, event: "handle_set_answer", payload: payload}, socket) do
    if socket.assigns.answer do
      {:noreply, socket}
    else
      {:noreply, assign(socket, answer: payload)}
    end
  end

  def handle_info(%{topic: _topic, event: "handle_readiness", payload: payload}, socket) do
    {:noreply, assign(socket, game_ready: payload.ready)}
  end

  def handle_info(
        %{topic: "game:" <> game_token, event: "check_readiness", payload: _payload},
        socket
      ) do
    game_state = GameRegistry.get(game_token)

    {:noreply, assign(socket, game_ready: game_ready?(game_token, game_state.expected_players))}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp get_answer(room_id) do
    case GameRegistry.get_path(room_id, [:answer]) do
      nil ->
        # replace with DB query
        word = Enum.random(~w(place tests space demos there three slate pacer))
        GameRegistry.merge(room_id, %{answer: word})
        get_answer(room_id)

      _ ->
        {:ok, %{answer: ""}}
    end
  end

  defp broadcast_readiness(topic, ready_state) do
    Endpoint.broadcast(topic, "handle_readiness", %{ready: ready_state})
  end

  defp game_ready?(game_token, expected_players) do
    Presence.list("game:#{game_token}")
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
