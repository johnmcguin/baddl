defmodule BaddlWeb.WordleLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    <div id="wordle-game" phx-hook="Wordle" phx-update="ignore"></div>
    """
  end
end
