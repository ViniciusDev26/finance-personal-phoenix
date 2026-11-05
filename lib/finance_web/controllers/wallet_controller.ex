defmodule FinanceWeb.WalletController do
  use FinanceWeb, :controller

  alias Finance.Wallets

  def create(conn, %{"wallet_operation" => operation_params}) do
    user_id = conn.assigns.current_user.id

    params =
      operation_params
      |> normalize_amount()
      |> Map.put("user_id", user_id)

    conn
    |> put_result_flash(Wallets.make_operation(params), "Movimentação registrada.")
    |> redirect(to: "/")
  end

  def update(conn, %{"wallet_operation" => operation_params}) do
    user_id = conn.assigns.current_user.id

    result =
      Wallets.update_operation(
        user_id,
        operation_params["id"],
        normalize_amount(operation_params)
      )

    conn
    |> put_result_flash(result, "Movimentação atualizada.")
    |> redirect(to: "/")
  end

  # Aceita "10,50" além de "10.50"; o Ecto converte a string para Decimal.
  defp normalize_amount(%{"amount" => amount} = params) when is_binary(amount) do
    Map.put(params, "amount", amount |> String.trim() |> String.replace(",", "."))
  end

  defp normalize_amount(params), do: params

  defp put_result_flash(conn, {:ok, _}, message), do: put_flash(conn, :info, message)

  defp put_result_flash(conn, {:error, :not_found}, _message),
    do: put_flash(conn, :error, "Movimentação não encontrada.")

  defp put_result_flash(conn, {:error, _}, _message),
    do: put_flash(conn, :error, "Não foi possível salvar a movimentação. Verifique os dados.")
end
