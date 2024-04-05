defmodule Baddl.GameRegistry do
  @moduledoc """
  This module is an Agent responsible for tracking some server side game state.
  """
  use Agent

  def start_link([]) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc """
  Gets the answer for a game.

  Returns nil if no answer is found.

  ## Examples

      iex> get_answer("tks2QdHA")
      "there"

      iex> get_answer("no_game")
      nil

  """
  def get_answer(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key) end)
  end

  @doc """
  Sets the answer for a game.

  Returns :ok atom

  Get the answer with get_answer/1 after set_answer/2

  ## Examples

      iex> set_answer("tks2QdHA", "there")
      :ok

  """
  def set_answer(key, value) do
    Agent.update(__MODULE__, fn state -> Map.put(state, key, value) end)
  end
end
