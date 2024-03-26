defmodule BaddlWeb.PageController do
  use BaddlWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false)
  end

  def new(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :new, layout: false)
  end
end
