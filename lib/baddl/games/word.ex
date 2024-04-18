defmodule Baddl.Games.Word do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "words" do
    field :word, :string, default: ""
  end

  @doc false
  def changeset(word, attrs) do
    word
    |> cast(attrs, [:word])
    |> validate_required([:word])
  end
end
