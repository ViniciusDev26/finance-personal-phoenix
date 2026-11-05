defmodule Finance.WalletsFixtures do
  @moduledoc """
  Helpers para criar movimentações via o contexto `Finance.Wallets`.
  """

  def operation_fixture(user, attrs \\ %{}) do
    {:ok, operation} =
      attrs
      |> Enum.into(%{
        "name" => "Operação",
        "details" => "Detalhes",
        "amount" => "100.00",
        "operation_type" => "DEPOSIT"
      })
      |> Map.put("user_id", user.id)
      |> Finance.Wallets.make_operation()

    operation
  end

  def balance(user), do: Finance.Wallets.get_wallet(user.id).balance
end
