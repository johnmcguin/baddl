defmodule BaddlWeb.WordleLive do
  use BaddlWeb, :live_view

  def render(assigns) do
    ~H"""
    <div id="wordle-game" phx-hook="Wordle" phx-update="ignore"></div>
    """
  end

  def mount(params, session, socket) do
    {:ok, socket}
  end
end
