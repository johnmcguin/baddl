defmodule BaddlWeb.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](https://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence,
    otp_app: :baddl,
    pubsub_server: Baddl.PubSub

  alias BaddlWeb.Endpoint

  def init(_opts), do: {:ok, %{}}

  def handle_metas(topic, _diff, _presences, state) do
    Endpoint.broadcast(topic, "check_readiness", %{})
    {:ok, state}
  end
end
