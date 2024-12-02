defmodule FinanceWeb.WalletController do
  use FinanceWeb, :controller

  alias Finance.Wallets.WalletOperation
  alias Finance.Wallets
  alias Finance.Repo


  def create(conn, params) do
    user_id = get_session(conn, :user_id)
    type = params["wallet_operation"]["operation_type"]

    params = Map.put(params["wallet_operation"], "user_id", user_id)
    |> Map.put("amount", String.to_integer(params["wallet_operation"]["amount"]))
    Wallets.make_operation(String.to_atom(type), params)

    redirect(conn, to: "/")
  end

  def update(conn, params) do
    operation = Repo.get(WalletOperation, params["wallet_operation"]["id"])
    changeset = WalletOperation.registration_changeset(operation, params["wallet_operation"])

    Wallets.update(changeset)

    redirect(conn, to: "/")
  end
end
