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
    {:ok, wallet} =
      %Wallet{user_id: user_id}
      |> Wallet.registration_changeset(%{balance: 0, currency: "BRL"})
      |> Repo.insert()

    wallet
  end

  @doc """
  Registra uma movimentação e aplica o valor no saldo da carteira do usuário.
  """
  def make_operation(operation_params) do
    wallet = get_wallet(operation_params["user_id"])

    Repo.transaction(fn ->
      with {:ok, operation} <-
             %WalletOperation{wallet_id: wallet.id}
             |> WalletOperation.registration_changeset(operation_params)
             |> Repo.insert(),
           {:ok, _wallet} <-
             wallet
             |> Wallet.set_balance(balance_effect(wallet.balance, operation, :apply))
             |> Repo.update() do
        operation
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Atualiza uma movimentação e corrige o saldo: desfaz o efeito antigo e aplica o novo.
  """
  def update_operation(%WalletOperation{} = operation, attrs) do
    Repo.transaction(fn ->
      wallet = Repo.get!(Wallet, operation.wallet_id)

      with {:ok, updated} <-
             operation
             |> WalletOperation.registration_changeset(attrs)
             |> Repo.update(),
           new_balance =
             wallet.balance
             |> balance_effect(operation, :revert)
             |> balance_effect(updated, :apply),
           {:ok, _wallet} <- wallet |> Wallet.set_balance(new_balance) |> Repo.update() do
        updated
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def delete_operation(operation_id) do
    operation = Repo.get!(WalletOperation, operation_id)

    Repo.transaction(fn ->
      wallet = Repo.get!(Wallet, operation.wallet_id)

      with {:ok, deleted} <- Repo.delete(operation),
           {:ok, _wallet} <-
             wallet
             |> Wallet.set_balance(balance_effect(wallet.balance, operation, :revert))
             |> Repo.update() do
        deleted
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  defp balance_effect(balance, %WalletOperation{operation_type: type, amount: amount}, mode) do
    case {type, mode} do
      {"DEPOSIT", :apply} -> Decimal.add(balance, amount)
      {"DEPOSIT", :revert} -> Decimal.sub(balance, amount)
      {"WITHDRAWAL", :apply} -> Decimal.sub(balance, amount)
      {"WITHDRAWAL", :revert} -> Decimal.add(balance, amount)
    end
  end
end
