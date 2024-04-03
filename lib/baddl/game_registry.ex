defmodule Baddl.GameRegistry do
  use Agent

  def start_link([]) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key) do
    Agent.get(__MODULE__, fn state -> Map.get(state, key) end)
  end

  def set(key, value) do
    Agent.update(__MODULE__, fn state -> Map.put(state, key, value) end)
  end
end
