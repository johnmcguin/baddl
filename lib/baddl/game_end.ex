defmodule Baddl.GameEnd do
  use GenServer
  require Logger
  alias BaddlWeb.Presence
  alias Baddl.Games

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  # client API
  def maybe_close_room(short_token) do
    Process.send_after(__MODULE__, {:check_game, short_token}, 1000)
  end

  # Server API
  @impl true
  def init(initial_state) do
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:check_game, short_token}, state) do
    Logger.info("checking whether to close game room #{inspect(short_token)}")

    if not players_present?(Games.room_topic(short_token)) do
      Logger.info("closing game room #{inspect(short_token)}")
      Games.close_room(short_token)
    end

    {:noreply, state}
  end

  @impl true
  def handle_info({:check_game, short_token}, state) do
    GenServer.cast(__MODULE__, {:check_game, short_token})
    {:noreply, state}
  end

  # Private helpers
  defp players_present?(topic) do
    Presence.list(topic)
    |> Enum.count()
    |> Kernel.>(0)
  end
end
