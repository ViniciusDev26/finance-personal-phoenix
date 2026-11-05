defmodule FinanceWeb.WalletControllerTest do
  use FinanceWeb.ConnCase

  import Finance.AccountsFixtures
  import Finance.WalletsFixtures

  alias Finance.Repo
  alias Finance.Wallets.WalletOperation

  setup :register_and_log_in_user

  describe "POST /wallet" do
    test "cria a movimentação aceitando vírgula decimal", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/wallet", %{
          "wallet_operation" => %{
            "name" => "Salário",
            "details" => "",
            "amount" => "1234,56",
            "operation_type" => "DEPOSIT"
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "registrada"
      assert Decimal.equal?(balance(user), "1234.56")
    end

    test "mostra erro com dados inválidos", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/wallet", %{
          "wallet_operation" => %{"name" => "x", "amount" => "abc", "operation_type" => "DEPOSIT"}
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error)
      assert Decimal.equal?(balance(user), 0)
    end
  end

  describe "PUT /wallet" do
    test "atualiza a movimentação do próprio usuário", %{conn: conn, user: user} do
      operation = operation_fixture(user, %{"amount" => "100"})

      conn =
        put(conn, ~p"/wallet", %{
          "wallet_operation" => %{"id" => to_string(operation.id), "amount" => "150,50"}
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "atualizada"
      assert Decimal.equal?(balance(user), "150.50")
    end

    test "não permite editar movimentação de outro usuário", %{conn: conn} do
      other = user_fixture()
      operation = operation_fixture(other, %{"amount" => "100", "name" => "Original"})

      conn =
        put(conn, ~p"/wallet", %{
          "wallet_operation" => %{
            "id" => to_string(operation.id),
            "name" => "Hack",
            "amount" => "1"
          }
        })

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "não encontrada"

      reloaded = Repo.get!(WalletOperation, operation.id)
      assert reloaded.name == "Original"
      assert Decimal.equal?(balance(other), "100")
    end

    test "id inexistente não quebra a requisição", %{conn: conn} do
      conn = put(conn, ~p"/wallet", %{"wallet_operation" => %{"id" => "999999999"}})

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "não encontrada"
    end
  end

  test "exige login", %{conn: _conn} do
    conn = post(build_conn(), ~p"/wallet", %{"wallet_operation" => %{}})
    assert redirected_to(conn) == ~p"/users/log_in"
  end
end
