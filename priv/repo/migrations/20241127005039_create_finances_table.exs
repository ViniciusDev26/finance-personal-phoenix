defmodule Finance.Repo.Migrations.CreateFinancesTable do
  use Ecto.Migration

  def change do
    execute(
      """
        CREATE TYPE operation_type AS ENUM ('DEPOSIT', 'WITHDRAWAL')
      """
    )
    create table(:wallet) do
      add :balance, :decimal, precision: 10, scale: 2
      add :currency, :string, default: "BRL"
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create table(:wallet_operations) do
      add :name, :string, null: false
      add :details, :string
      add :amount, :decimal, precision: 10, scale: 2
      add :operation_type, :operation_type, null: false
      add :wallet_id, references(:wallet, on_delete: :delete_all)
      timestamps()
    end
  end
end
