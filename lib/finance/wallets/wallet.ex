defmodule Finance.Wallets.Wallet do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallet" do
    field :balance, :decimal
    field :currency, :string
    belongs_to :user, Finance.Accounts.User
  end

  def registration_changeset(wallet, attrs, opts \\ []) do
    wallet
    |> cast(attrs, [:balance, :currency])
    |> validate_balance(opts)
    |> validate_currency(opts)
    |> validate_user_id(opts)
  end

  def validate_balance(changeset, _opts) do
    changeset
    |> validate_required([:balance])
    |> validate_number(:balance, greater_than_or_equal_to: 0)
  end

  def validate_currency(changeset, _opts) do
    changeset
    |> validate_required([:currency])
    |> validate_inclusion(:currency, ["BRL", "USD", "EUR"])
  end

  def validate_user_id(changeset, _opts) do
    changeset
    |> validate_required([:user_id])
  end

  def deposit(wallet, amount) do
    wallet
    |> Ecto.Changeset.change(balance: wallet.balance + amount)
  end

  def withdraw(wallet, amount) do
    wallet
    |> Ecto.Changeset.change(balance: wallet.balance - amount)
  end
end
