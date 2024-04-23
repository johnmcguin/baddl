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

  @doc """
  Handler for an empty game lobby. "Close" the game room by ending it.
  """
  def handle_metas("game:" <> game_token, _diff, presences, state) when presences == %{} do
    case Games.close_room(game_token) do
      {:ok, _updates} ->
        Logger.info("#{__MODULE__} closed game room: #{game_token}")

      {:error, reason} ->
        Logger.error("#{__MODULE__} could not close game room: #{game_token}")
        Logger.error(inspect(reason))
    end

    {:ok, state}
  end

  def handle_metas("game:" <> _game_token, _diff, _presences, state) do
    {:ok, state}
  end

  def handle_metas("all_players", _diff, _presences, state) do
    Endpoint.broadcast("all_players", "player_joined", %{})
    {:ok, state}
  end
end
