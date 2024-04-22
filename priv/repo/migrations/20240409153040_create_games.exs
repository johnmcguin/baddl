defmodule Baddl.Repo.Migrations.CreateGames do
  use Ecto.Migration

  def change do
    create table(:games, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :answer, :string, null: false
      add :room_id, references(:rooms, on_delete: :delete_all, type: :binary_id)
      add :ended_at, :utc_datetime
      add :won_by, :string

      timestamps(type: :utc_datetime)
    end

    create index(:games, [:room_id])
  end
end
