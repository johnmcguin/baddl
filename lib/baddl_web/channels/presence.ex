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

  def handle_metas("game:" <> game_token, diff, presences, state) do
    if all_left?(diff.leaves, presences) do
      Games.close_room(game_token)
    end

    {:ok, state}
  end

  def handle_metas("all_players", _diff, _presences, state) do
    Endpoint.broadcast("all_players", "player_joined", %{})
    {:ok, state}
  end

  defp all_left?(leaves, presences) do
    leaving = Map.keys(leaves) |> MapSet.new()
    present = Map.keys(presences) |> MapSet.new()

    IO.puts("""
    leaving is
    #{inspect(leaving, pretty: true)}
    """)

    IO.puts("""
    present is
    #{inspect(present, pretty: true)}
    """)

    MapSet.difference(present, leaving)
    |> MapSet.to_list()
    |> length()
    |> Kernel.==(0)
  end
end
