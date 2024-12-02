defmodule Finance.Wallets do
  import Ecto.Query, warn: false
  alias Finance.Repo

  alias Finance.Wallets.{Wallet, WalletOperation}

  def get_wallet(user_id) do
    wallet = Repo.get_by(Wallet, user_id: user_id)
    if wallet do
      wallet
    else
      create_wallet(user_id)
    end
  end

  def get_wallet_history(user_id) do
    query = from w_o in WalletOperation,
      join: w in Wallet,
      on: w_o.wallet_id == w.id,
      where: w.user_id == ^user_id,
      order_by: [desc: w_o.inserted_at],
      select: %{id: w_o.id,name: w_o.name, details: w_o.details, amount: w_o.amount, operation_type: w_o.operation_type, inserted_at: w_o.inserted_at}
    Repo.all(query)
  end

  def create_wallet(user_id) do
    %Wallet{user_id: user_id}
    |> Wallet.registration_changeset(%{balance: 0, currency: "BRL"})
    |> Repo.insert()
  end

  def make_operation(:DEPOSIT, operation_params) do
    wallet = get_wallet(operation_params["user_id"])
    %WalletOperation{wallet_id: wallet.id}
    |> WalletOperation.registration_changeset(operation_params)
    |> Repo.insert()

    Wallet.deposit(wallet, operation_params["amount"]) |> Repo.update()
  end

  def make_operation(:WITHDRAWAL, operation_params) do
    wallet = get_wallet(operation_params["user_id"])
    %WalletOperation{wallet_id: wallet.id}
    |> WalletOperation.registration_changeset(operation_params)
    |> Repo.insert()
    |> IO.inspect()

    Wallet.withdraw(wallet, operation_params["amount"]) |> Repo.update()
  end

  def delete_operation(operation_id) do
    operation = Repo.get(WalletOperation, operation_id)
    wallet = Repo.get(Wallet, operation.wallet_id)
    Repo.delete(operation)
    if operation.operation_type == "DEPOSIT" do
      Wallet.withdraw(wallet, operation.amount) |> Repo.update()
    else
      Wallet.deposit(wallet, operation.amount) |> Repo.update()
    end
  end
end
