defmodule Baddl.Repo.Migrations.AddPlayerCount do
  use Ecto.Migration

  def change do
    alter table(:rooms) do
      add :num_players, :integer
    end
  end
end
