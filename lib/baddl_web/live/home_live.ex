defmodule BaddlWeb.HomeLive do
  use BaddlWeb, :live_view
  alias Baddl.Games.Room

  def mount(_params, _session, socket) do
    create_changeset = Room.changeset_for_create(%{})
    join_changeset = Room.changeset_for_join(%{})

    socket =
      socket
      |> assign_create_form(create_changeset)
      |> assign_join_form(join_changeset)

    {:ok, socket}
  end

  defp assign_create_form(socket, %Ecto.Changeset{} = create_changeset) do
    create_form = to_form(create_changeset, as: "create_game")
    assign(socket, create_form: create_form)
  end

  defp assign_join_form(socket, %Ecto.Changeset{} = join_changeset) do
    join_form = to_form(join_changeset, as: "join_game")
    assign(socket, join_form: join_form)
  end

  def handle_event("save", %{"create_game" => create_game_params}, socket) do
    _changeset = Room.changeset_for_create(create_game_params)
    # 1. create the Room
    # 2. on success, navigate to the game, passing the player name

    {:noreply, socket}
  end

  def handle_event("save", %{"join_game" => join_game_params}, socket) do
    _changeset = Room.changeset_for_create(join_game_params)
    # 1. create the Room
    # 2. on success, navigate to the game, passing the player name

    {:noreply, socket}
  end

  def handle_event("validate", %{"create_game" => create_game_params}, socket) do
    changeset = Room.changeset_for_create(create_game_params)
    {:noreply, assign_create_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("validate", %{"join_game" => join_game_params}, socket) do
    changeset = Room.changeset_for_join(join_game_params)

    IO.puts("""
    changeset is
    #{inspect(changeset, pretty: true)}
    """)

    {:noreply, assign_join_form(socket, Map.put(changeset, :action, :validate))}
  end
end
