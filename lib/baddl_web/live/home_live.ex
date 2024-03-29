defmodule BaddlWeb.HomeLive do
  use BaddlWeb, :live_view

  def mount(_params, _session, socket) do
    # {:ok, assign(socket, query: nil, result: nil, loading: false, matches: [])}
    {:ok, socket}
  end
end
