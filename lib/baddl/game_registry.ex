defmodule Baddl.GameRegistry do
  @moduledoc """
  This module is an Agent responsible for tracking some server side game state.
  """
  use Agent

  def start_link([]) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Gets the game state.

  Returns nil if no game state is found.

  ## Examples

      iex> get("tks2QdHA")
      %{answer: "there"}

      iex> get("no_game")
      nil

  """
  def get(key), do: Agent.get(__MODULE__, fn state -> Map.get(state, key) end)

  def get_path(key, path) do
    Agent.get(__MODULE__, fn state ->
      get_in(state, [key] ++ path)
    end)
  end

  @doc """
  Sets/updates the game state.

  Returns :ok atom

  Get the game state with get/1 after set/2

  ## Examples

      iex> merge("tks2QdHA", %{answer: "there"})
      :ok

  """
  def merge(key, updates), do: Agent.update(__MODULE__, &merge_updates(&1, key, updates))

  @doc false
  defp merge_updates(agent_state, key, updates) do
    {_old, new} =
      Map.get_and_update(agent_state, key, fn current_state ->
        current_value = if is_nil(current_state), do: %{}, else: current_state
        {current_value, Map.merge(current_value, updates)}
      end)

    new
  end
end
