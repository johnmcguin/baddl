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

  def render(assigns) do
    ~H"""
    <div><%= @name %></div>
    <div><%= @messages %></div>
    <div id="wordle-game" phx-hook="Wordle" phx-update="ignore" data-answer={@answer}></div>
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

      %Room{} = _room ->
        Endpoint.subscribe("game:#{id}")

        {:ok, socket}
    end
  end

  def handle_params(%{"name" => name, "id" => id}, _url, socket) do
    socket =
      socket
      |> assign(name: name)
      |> assign(room_id: id)
      |> assign(messages: nil)
      |> assign(answer: "three")

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
    {:noreply, assign(socket, messages: "hello from #{payload.player}")}
  end

  def handle_info(_event, socket) do
    {:noreply, socket}
  end
end
