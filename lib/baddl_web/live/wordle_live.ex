defmodule BaddlWeb.WordleLive do
  @moduledoc """
  Wordle LiveView

  Renders the wordle elm app.
  Shows the current game status realtime (reporting on each player status)
  """
  use BaddlWeb, :live_view
  alias BaddlWeb.Endpoint
  alias Baddl.Games.Room
  alias Baddl.Games
  alias Baddl.GameRegistry

  def render(assigns) do
    ~H"""
    <.async_result :let={answer} assign={@answer}>
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
    case Games.get_room_by(short_token: id) do
      nil ->
        socket
        |> put_flash(:error, "Game room #{id} not found")
        |> push_navigate(to: "/")
        |> then(fn socket -> {:noreply, socket} end)

      %Room{} ->
        Endpoint.subscribe("game:#{id}")

        socket
        |> assign(name: name)
        |> assign(room_id: id)
        |> assign(messages: %{})
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

  def handle_info(_event, socket) do
    {:noreply, socket}
  end

  defp get_answer(room_id) do
    case GameRegistry.get(room_id) do
      nil ->
        # replace with DB query
        word = Enum.random(~w(place tests space demos there three slate pacer))
        GameRegistry.set(room_id, %{answer: word})
        get_answer(room_id)

      results ->
        {:ok, %{answer: results.answer}}
    end
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
