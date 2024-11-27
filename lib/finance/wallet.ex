defmodule Finance.Wallets do
  import Ecto.Query, warn: false
  alias Finance.Repo

  alias Finance.Wallets.{Wallet, WalletOperation}

  def get_wallet(user_id) when is_binary(user_id) do
    Repo.get_by(Wallet, user_id: user_id)
  end

  def get_wallet_history(user_id) when is_binary(user_id) do
    query = from w_o in WalletOperation,
      join: w in Wallet,
      on: w_o.wallet_id == w.id,
      where: w.user_id == ^user_id,
      order_by: [desc: w_o.inserted_at],
      select: %{name: w_o.name, details: w_o.details, amount: w_o.amount, operation_type: w_o.operation_type, inserted_at: w_o.inserted_at}
    Repo.all(query)
  end

  def create_wallet(user_id) when is_binary(user_id) do
    %Wallet{user_id: user_id}
    |> Wallet.registration_changeset(%{balance: 0, currency: "BRL"})
    |> Repo.insert()
  end

  def make_operation(:deposit, operation_params) do
    wallet = get_wallet(operation_params["user_id"])
    %WalletOperation{}
    |> WalletOperation.registration_changeset(operation_params)
    |> Repo.insert()

    Wallet.deposit(wallet, operation_params["amount"])
  end

  def make_operation(:withdrawal, operation_params) do
    wallet = get_wallet(operation_params["user_id"])
    %WalletOperation{}
    |> WalletOperation.registration_changeset(operation_params)
    |> Repo.insert()

    Wallet.withdraw(wallet, operation_params["amount"])
  end
end
