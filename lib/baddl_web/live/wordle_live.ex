defmodule BaddlWeb.WordleLive do
  @moduledoc """
  Wordle LiveView

  Renders the wordle elm app.
  Shows the current game status realtime (reporting on each player status)
  """
  use BaddlWeb, :live_view
  alias BaddlWeb.Endpoint
  alias Baddl.Repo
  alias Baddl.Games.Room
  alias Baddl.Games

  def render(assigns) do
    ~H"""
    <div class="messages"><%= @name %></div>
    <div :if={@msg}><%= @msg %></div>
    <div id="wordle-game" phx-hook="Wordle" phx-update="ignore"></div>
    """
  end

  def mount(%{"id" => id}, _session, socket) do
    case Games.get_room_by(short_token: id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Game room #{id} not found")
          |> push_navigate(to: "/")

        {:ok, socket}

      %Room{} = room ->
        Endpoint.subscribe("game:#{id}")
        {:ok, socket}
    end
  end

  def handle_params(%{"name" => name, "id" => id}, _url, socket) do
    socket =
      socket
      |> assign_current_player(name)
      |> assign_game_id(id)
      |> assign(:msg, nil)

    {:noreply, socket}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, push_patch(socket, to: "/game/#{id}?name=Guest")}
  end

  def handle_event("handle_guess", made_guess, socket) do
    Endpoint.broadcast_from(self(), "game:#{socket.assigns.room_id}", "handle_player_guess", %{
      player: socket.assigns.name,
      guess: made_guess
    })

    {:noreply, socket}
  end

  # handles info broadcast from other LiveViews
  def handle_info(%{topic: _topic, event: "handle_player_guess", payload: payload}, socket) do
    {:noreply, assign(socket, msg: "hello from #{payload.player}")}
  end

  def assign_current_player(socket, name) do
    assign(socket, name: name)
  end

  def assign_game_id(socket, id) do
    assign(socket, room_id: id)
  end
end
