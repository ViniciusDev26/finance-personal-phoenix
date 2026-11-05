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
  Busca uma movimentação garantindo que ela pertence à carteira do usuário.
  Retorna `nil` se não existir, for de outro usuário ou o id for inválido.
  """
  def get_user_operation(user_id, operation_id) do
    case Ecto.Type.cast(:id, operation_id) do
      {:ok, id} when is_integer(id) ->
        Repo.one(
          from w_o in WalletOperation,
            join: w in Wallet,
            on: w_o.wallet_id == w.id,
            where: w_o.id == ^id and w.user_id == ^user_id
        )

      _ ->
        nil
    end
  end

  @doc """
  Atualiza uma movimentação do usuário e corrige o saldo: desfaz o efeito
  antigo e aplica o novo. Retorna `{:error, :not_found}` se a movimentação
  não pertencer ao usuário.
  """
  def update_operation(user_id, operation_id, attrs) do
    with %WalletOperation{} = operation <- get_user_operation(user_id, operation_id) do
      # A carteira de uma movimentação nunca muda pela edição.
      attrs = Map.drop(attrs, ["wallet_id", :wallet_id])

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
    else
      nil -> {:error, :not_found}
    end
  end

  @doc """
  Remove uma movimentação do usuário e desfaz o efeito no saldo.
  Retorna `{:error, :not_found}` se a movimentação não pertencer ao usuário.
  """
  def delete_operation(user_id, operation_id) do
    with %WalletOperation{} = operation <- get_user_operation(user_id, operation_id) do
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
    else
      nil -> {:error, :not_found}
    end
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
