defmodule BaddlWeb.HomeLive do
  use BaddlWeb, :live_view
  alias Baddl.Games.Room
  alias Baddl.Repo

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
    name = create_game_params["display_name"]
    num_players = create_game_params["num_players"]
    changeset = Room.changeset_for_create(%{display_name: name, num_players: num_players})
    room = Room.create(%{num_players: num_players})

    if changeset.valid? do
      case Repo.insert(room) do
        {:ok, %Room{} = struct} ->
          {:noreply, push_navigate(socket, to: "/game/#{struct.short_token}?name=#{name}")}

        {:error, err_changeset} ->
          {:noreply, assign_create_form(socket, err_changeset)}
      end
    else
      {:noreply, assign_create_form(socket, changeset)}
    end
  end

  def handle_event("save", %{"join_game" => join_game_params}, socket) do
    name = join_game_params["display_name"]
    room_id = join_game_params["room_id"]
    changeset = Room.changeset_for_create(join_game_params)

    if changeset.valid? do
      {:noreply, push_navigate(socket, to: "/game/#{room_id}?name=#{name}")}
    else
      {:noreply, assign_join_form(socket, changeset)}
    end
  end

  def handle_event("validate", %{"create_game" => create_game_params}, socket) do
    changeset = Room.changeset_for_create(create_game_params)
    {:noreply, assign_create_form(socket, Map.put(changeset, :action, :validate))}
  end

  def handle_event("validate", %{"join_game" => join_game_params}, socket) do
    changeset = Room.changeset_for_join(join_game_params)
    {:noreply, assign_join_form(socket, Map.put(changeset, :action, :validate))}
  end
end
