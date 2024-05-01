defmodule BaddlWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :baddl,
    pubsub_server: Baddl.PubSub

  require Logger
  alias BaddlWeb.Endpoint
  alias Baddl.Games

  def init(_opts), do: {:ok, %{}}

  def handle_metas("game:" <> game_token, %{leaves: leaves}, presences, state)
      when presences == %{} do
    case Enum.count(leaves) > 0 do
      true ->
        Games.close_room(game_token)
        {:ok, state}

      false ->
        {:ok, state}
    end
  end

  def handle_metas("game:" <> _game_token, _diff, _presences, state) do
    {:ok, state}
  end

  def handle_metas("all_players", _diff, _presences, state) do
    Endpoint.broadcast("all_players", "player_joined", %{})
    {:ok, state}
  end
end
