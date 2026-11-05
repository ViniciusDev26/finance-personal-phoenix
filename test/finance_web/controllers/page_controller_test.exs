defmodule FinanceWeb.PageControllerTest do
  use FinanceWeb.ConnCase

  test "GET / redirects to login when not authenticated", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/users/log_in"
  end

  describe "authenticated" do
    setup :register_and_log_in_user

    test "GET / renders the wallet", %{conn: conn} do
      conn = get(conn, ~p"/")
      assert html_response(conn, 200) =~ "Nova movimentação"
    end
  end
end
