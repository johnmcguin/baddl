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
    # will likely need to loop over an array of n number 
    # game players. For each player that is not the current user,
    # show their status of guesses
    ~H"""
    <div class="messages"><%= @name %></div>
    <div id="wordle-game" phx-hook="Wordle" phx-update="ignore"></div>
    """
  end

  # get the cookie from a plug and assign it to the session.
  # configure the cookie to be long lived. Use this as client 
  # id 
  def mount(%{"id" => id}, session, socket) do
    # Subscribe to the game topic
    # e.g. Endpoint.subscribe("game:<game_id>")
    # assign any relevant info to the socket (may not be any right now)
    case Games.get_room_by(short_token: id) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Game room #{id} not found")
          |> push_navigate(to: "/")

        {:ok, socket}

      %Room{} = room ->
        {:ok, socket}
    end
  end

  def handle_params(%{"name" => name, "id" => id}, _url, socket) do
    {:noreply, assign_current_player(socket, name)}
  end

  def handle_params(%{"id" => id}, _url, socket) do
    {:noreply, push_patch(socket, to: "/game/#{id}?name=Guest")}
  end

  # handle_event receives events from the game client
  def handle_event(step, _value, socket) do
    # broadcast the event from pid's self so that the other liveviews
    # get notified
    # Endpoint.broadcast_from(self(), @topic, step, state)
    # may only need to broadcast since client who gave their update does not need to be updated (elm is showing them this state)
    # If needed, can send message to self()
    # send(self(), next_step)
    {:noreply, socket}
  end

  def assign_current_player(socket, name) do
    assign(socket, name: name)
  end
end
