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

  def init(_opts) do
    {:ok, %{counts: %{}}}
  end

  def handle_metas(
        "game:" <> game_token,
        %{joins: joins, leaves: leaves},
        _presences,
        %{counts: counts} = state
      ) do
    join_count = Map.keys(joins) |> length()
    leave_count = Map.keys(leaves) |> length()

    counts = Map.update(counts, game_token, join_count, &(&1 + join_count - leave_count))

    room_empty = room_empty?(counts, game_token)

    if room_empty do
      Baddl.GameEnd.maybe_close_room(game_token)
    end

    counts = if(room_empty, do: Map.delete(counts, game_token), else: counts)

    {:ok, %{state | counts: counts}}
  end

  def handle_metas("all_players", _diff, _presences, state) do
    Endpoint.broadcast("all_players", "player_joined", %{})
    {:ok, state}
  end

  defp room_empty?(counts, game_token), do: counts[game_token] == 0
end
