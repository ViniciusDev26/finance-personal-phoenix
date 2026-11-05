defmodule Finance.WalletsTest do
  use Finance.DataCase

  import Finance.AccountsFixtures
  import Finance.WalletsFixtures

  alias Finance.Wallets
  alias Finance.Wallets.WalletOperation

  setup do
    %{user: user_fixture(), other_user: user_fixture()}
  end

  describe "get_wallet/1" do
    test "cria a carteira com saldo zero no primeiro acesso", %{user: user} do
      wallet = Wallets.get_wallet(user.id)
      assert wallet.user_id == user.id
      assert Decimal.equal?(wallet.balance, 0)
      assert wallet.currency == "BRL"
    end
  end

  describe "make_operation/1" do
    test "entrada soma ao saldo, aceitando centavos", %{user: user} do
      operation_fixture(user, %{"amount" => "1000.50", "operation_type" => "DEPOSIT"})
      assert Decimal.equal?(balance(user), "1000.50")
    end

    test "saída subtrai do saldo", %{user: user} do
      operation_fixture(user, %{"amount" => "100", "operation_type" => "DEPOSIT"})
      operation_fixture(user, %{"amount" => "30.25", "operation_type" => "WITHDRAWAL"})
      assert Decimal.equal?(balance(user), "69.75")
    end

    test "dados inválidos não gravam nada nem alteram o saldo", %{user: user} do
      assert {:error, %Ecto.Changeset{}} =
               Wallets.make_operation(%{
                 "user_id" => user.id,
                 "name" => "x",
                 "amount" => "abc",
                 "operation_type" => "DEPOSIT"
               })

      assert Wallets.get_wallet_history(user.id) == []
      assert Decimal.equal?(balance(user), 0)
    end
  end

  describe "get_user_operation/2" do
    test "retorna a movimentação do próprio usuário", %{user: user} do
      operation = operation_fixture(user)
      assert %WalletOperation{id: id} = Wallets.get_user_operation(user.id, operation.id)
      assert id == operation.id
    end

    test "retorna nil para movimentação de outro usuário", %{user: user, other_user: other} do
      operation = operation_fixture(other)
      assert Wallets.get_user_operation(user.id, operation.id) == nil
    end
  end

  describe "update_operation/3" do
    test "ajusta o saldo ao mudar o valor", %{user: user} do
      operation = operation_fixture(user, %{"amount" => "100", "operation_type" => "DEPOSIT"})

      assert {:ok, updated} =
               Wallets.update_operation(user.id, operation.id, %{"amount" => "250.50"})

      assert Decimal.equal?(updated.amount, "250.50")
      assert Decimal.equal?(balance(user), "250.50")
    end

    test "ajusta o saldo ao trocar o tipo", %{user: user} do
      operation = operation_fixture(user, %{"amount" => "100", "operation_type" => "DEPOSIT"})

      assert {:ok, _} =
               Wallets.update_operation(user.id, operation.id, %{"operation_type" => "WITHDRAWAL"})

      assert Decimal.equal?(balance(user), -100)
    end

    test "não altera movimentação de outro usuário", %{user: user, other_user: other} do
      operation = operation_fixture(other, %{"amount" => "100", "name" => "Original"})

      assert {:error, :not_found} =
               Wallets.update_operation(user.id, operation.id, %{
                 "amount" => "1",
                 "name" => "Hack"
               })

      reloaded = Repo.get!(WalletOperation, operation.id)
      assert reloaded.name == "Original"
      assert Decimal.equal?(reloaded.amount, "100")
      assert Decimal.equal?(balance(other), "100")
      assert Decimal.equal?(balance(user), 0)
    end

    test "não permite mover a movimentação para a carteira de outro usuário",
         %{user: user, other_user: other} do
      operation = operation_fixture(user, %{"amount" => "100"})
      other_wallet = Wallets.get_wallet(other.id)

      assert {:ok, _} =
               Wallets.update_operation(user.id, operation.id, %{"wallet_id" => other_wallet.id})

      assert Repo.get!(WalletOperation, operation.id).wallet_id == Wallets.get_wallet(user.id).id
      assert Decimal.equal?(balance(user), "100")
      assert Decimal.equal?(balance(other), 0)
    end

    test "id inválido retorna :not_found", %{user: user} do
      assert {:error, :not_found} = Wallets.update_operation(user.id, "abc", %{})
      assert {:error, :not_found} = Wallets.update_operation(user.id, -1, %{})
    end

    test "dados inválidos não alteram o saldo", %{user: user} do
      operation = operation_fixture(user, %{"amount" => "100"})

      assert {:error, %Ecto.Changeset{}} =
               Wallets.update_operation(user.id, operation.id, %{"amount" => "-5"})

      assert Decimal.equal?(balance(user), "100")
    end
  end

  describe "delete_operation/2" do
    test "remove a movimentação e desfaz o efeito no saldo", %{user: user} do
      operation_fixture(user, %{"amount" => "100", "operation_type" => "DEPOSIT"})
      withdrawal = operation_fixture(user, %{"amount" => "40", "operation_type" => "WITHDRAWAL"})

      assert {:ok, _} = Wallets.delete_operation(user.id, withdrawal.id)
      refute Repo.get(WalletOperation, withdrawal.id)
      assert Decimal.equal?(balance(user), "100")
    end

    test "não remove movimentação de outro usuário", %{user: user, other_user: other} do
      operation = operation_fixture(other, %{"amount" => "100"})

      assert {:error, :not_found} = Wallets.delete_operation(user.id, operation.id)
      assert Repo.get(WalletOperation, operation.id)
      assert Decimal.equal?(balance(other), "100")
    end
  end
end
