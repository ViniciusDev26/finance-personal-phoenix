defmodule Finance.Repo do
  use Ecto.Repo,
    otp_app: :finance,
    adapter: Ecto.Adapters.Postgres
end
