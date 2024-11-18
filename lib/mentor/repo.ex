defmodule Mentor.Repo do
  use Ecto.Repo,
    otp_app: :mentor,
    adapter: Ecto.Adapters.SQLite3
end
