defmodule FinanceWeb.WalletHomeLiveTest do
  use FinanceWeb.ConnCase

  import Phoenix.LiveViewTest
  import Finance.AccountsFixtures
  import Finance.WalletsFixtures

  alias Finance.Repo
  alias Finance.Wallets.WalletOperation

  setup :register_and_log_in_user

  test "lista só as movimentações do usuário logado", %{conn: conn, user: user} do
    operation_fixture(user, %{"name" => "Minha conta de luz"})
    operation_fixture(user_fixture(), %{"name" => "Conta de outra pessoa"})

    {:ok, _lv, html} = live(conn, ~p"/")

    assert html =~ "Minha conta de luz"
    refute html =~ "Conta de outra pessoa"
  end

  describe "excluir" do
    test "remove a própria movimentação", %{conn: conn, user: user} do
      operation = operation_fixture(user)
      {:ok, lv, _html} = live(conn, ~p"/")

      render_click(lv, "delete", %{"id" => to_string(operation.id)})

      refute Repo.get(WalletOperation, operation.id)
    end

    test "não remove movimentação de outro usuário", %{conn: conn} do
      other = user_fixture()
      operation = operation_fixture(other, %{"amount" => "100"})
      {:ok, lv, _html} = live(conn, ~p"/")

      render_click(lv, "delete", %{"id" => to_string(operation.id)})

      assert Repo.get(WalletOperation, operation.id)
      assert Decimal.equal?(balance(other), "100")
    end
  end

  describe "editar" do
    test "abre o formulário com a própria movimentação", %{conn: conn, user: user} do
      operation = operation_fixture(user, %{"name" => "Aluguel"})
      {:ok, lv, _html} = live(conn, ~p"/")

      html = render_click(lv, "edit", %{"id" => to_string(operation.id)})

      assert html =~ ~s(value="Aluguel")
    end

    test "não expõe movimentação de outro usuário", %{conn: conn} do
      operation = operation_fixture(user_fixture(), %{"name" => "Dado sigiloso"})
      {:ok, lv, _html} = live(conn, ~p"/")

      html = render_click(lv, "edit", %{"id" => to_string(operation.id)})

      refute html =~ "Dado sigiloso"
      assert html =~ "não encontrada"
    end
  end
end
