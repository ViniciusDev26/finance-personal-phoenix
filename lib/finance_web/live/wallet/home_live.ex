defmodule FinanceWeb.WalletHomeLive do
alias Finance.Wallets.WalletOperation
alias Finance.Repo
alias Finance.Wallets
  use FinanceWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full flex flex-col gap-2 px-6">
      <div class="flex justify-center gap-2">
        <.card label="Valor atual:" currency={@wallet.currency} amount={@wallet.balance} />
        <div class="flex flex-col gap-2">
          <.card label="Entrada:" currency={@wallet.currency} amount={@wallet_operations_DEPOSIT} />
          <.card label="Saida:" currency={@wallet.currency} amount={@wallet_operations_WITHDRAWN} />
        </div>
      </div>
      <.button phx-click={show_modal("operation-modal")}>Nova movimentação</.button>
      <.modal show={@show} id="operation-modal">
        <.simple_form for={@form} id="create_operation_form" action={~p"/wallet"} phx-update="ignore">
          <.input label="Nome da operação" field={@form[:name]} type="text"/>
          <.input label="Descrição" field={@form[:details]} type="text" />
          <.input label="Valor" field={@form[:amount]} type="number"/>
          <.input label="Tipo" type="select" field={@form[:operation_type]} options={[:DEPOSIT, :WITHDRAWAL]}/>
          <.button phx-click={hide_modal("operation-modal")}>Salvar</.button>
        </.simple_form>
      </.modal>
      <table class="w-full text-sm text-left rtl:text-right text-gray-500">
        <thead class="text-xs text-gray-700 uppercase bg-gray-50">
          <tr>
            <th>Nome</th>
            <th>Descrição</th>
            <th>Valor</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <%= for operation <- @wallet_operations do %>
            <tr class={"bg-white border-b rounded p-8 #{if operation.operation_type == "DEPOSIT", do: "bg-emerald-100", else: "bg-red-100"  }"}>
              <td><%= operation.name %></td>
              <td><%= operation.details %></td>
              <td><%= operation.amount %></td>
              <td>
                <.button class="bg-transparent text-black p-0" phx-click="edit" phx-value-id={operation.id}>Editar</.button>
                <.button class="bg-transparent text-red-400 p-0" phx-click="delete" phx-value-id={operation.id}>Excluir</.button>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  def mount(_params, session, socket) do
    wallet = Wallets.get_wallet(session["user_id"])
    wallet_operations = Wallets.get_wallet_history(session["user_id"])
    wallet_operations_DEPOSIT = Enum.filter(wallet_operations, fn operation -> operation.operation_type == "DEPOSIT" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)
    wallet_operations_WITHDRAWN = Enum.filter(wallet_operations, fn operation -> operation.operation_type == "WITHDRAWAL" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)
    form = to_form(%{}, as: "wallet_operation")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form, show: true, wallet: wallet, wallet_operations: wallet_operations, wallet_operations_DEPOSIT: wallet_operations_DEPOSIT, wallet_operations_WITHDRAWN: wallet_operations_WITHDRAWN]}
  end

  def handle_event("delete", params, socket) do
    Wallets.delete_operation(params["id"])
    {:noreply, assign(socket, %{})}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    {:noreply, assign(socket, id: "operation-modal", show: true)}
  end
end
