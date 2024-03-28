defmodule BaddlWeb.PageController do
  use BaddlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
