defmodule Finance.Wallets.WalletOperation do
  use Ecto.Schema
  import Ecto.Changeset

  schema "wallet_operations" do
    field :name, :string
    field :details, :string
    field :amount, :decimal
    field :operation_type, :string
    belongs_to :wallet, Finance.Wallets.Wallet
    timestamps(type: :utc_datetime)
  end

  def registration_changeset(wallet_operation, attrs, opts \\ []) do
    wallet_operation
    |> cast(attrs, [:name, :details, :amount, :operation_type, :wallet_id])
    |> validate_amount(opts)
    |> validate_operation_type(opts)
    |> validate_wallet_id(opts)
  end

  def validate_amount(changeset, _opts) do
    changeset
    |> validate_required([:amount])
    |> validate_number(:amount, greater_than_or_equal_to: 0)
  end

  def validate_operation_type(changeset, _opts) do
    changeset
    |> validate_required([:operation_type])
    |> validate_inclusion(:operation_type, ["DEPOSIT", "WITHDRAWAL"])
  end

  def validate_wallet_id(changeset, _opts) do
    changeset
    |> validate_required([:wallet_id])
  end
end
