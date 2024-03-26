defmodule Baddl.Repo do
  use Ecto.Repo,
    otp_app: :baddl,
    adapter: Ecto.Adapters.SQLite3
end
