defmodule FinanceWeb.WalletHomeLive do
alias Finance.Wallets.WalletOperation
alias Finance.Repo
alias Finance.Wallets
  use FinanceWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full flex flex-col gap-2 px-6">
      <form>
        <.input label="Filtro" type="select" id="filter" name="filter" phx-change="filter" value="" options={["Ultimo Mes", "Ultimo Semestre", "Maiores saidas", "Maiores entradas"]}/>
      </form>
      <div class="flex justify-center gap-2">
        <.card label="Entrada:" currency={"BRL"} amount={@wallet_operations_DEPOSIT} />
        <.card label="Saida:" currency={"BRL"} amount={@wallet_operations_WITHDRAWN} />
      </div>
      <.button phx-click={"show_modal"}>Nova movimentação</.button>
      <%= if @show == true do %>
        <.modal show={true} on_cancel={hide_modal("operation-modal")} id="operation-modal">
          <.simple_form for={@form} action="/wallet" method={if @editing == true, do: "put", else: "post"}>
            <%= if @editing == true do %>
              <.input label="ID" field={@form[:id]} type="text"/>
            <% end %>
            <.input label="Nome da operação" field={@form[:name]} type="text"/>
            <.input label="Descrição" field={@form[:details]} type="text" />
            <.input label="Valor" field={@form[:amount]} type="number"/>
            <.input label="Tipo" type="select" field={@form[:operation_type]} options={[:DEPOSIT, :WITHDRAWAL]}/>
            <.button phx-click={hide_modal("operation-modal")}>Salvar</.button>
          </.simple_form>
        </.modal>
      <% end %>
      <table class="w-full text-sm text-left rtl:text-right text-gray-500">
        <thead class="text-xs text-gray-700 uppercase bg-gray-50">
          <tr>
            <th>Nome</th>
            <th>Descrição</th>
            <th>Valor</th>
            <th>Data da operação</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <%= for operation <- @wallet_operations do %>
            <tr class={"bg-white border-b rounded p-8 #{if operation.operation_type == "DEPOSIT", do: "bg-emerald-100", else: "bg-red-100"  }"}>
              <td><%= operation.name %></td>
              <td><%= operation.details %></td>
              <td><%= operation.amount %></td>
              <td><%=
                {:ok, date} = Timex.format(operation.inserted_at, "{0D}/{0M}/{YYYY} {h24}:{0m}")
                date
              %></td>
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
    _ = Wallets.get_wallet(session["user_id"])
    wallet_operations = Wallets.get_wallet_history(session["user_id"])
    wallet_operations_DEPOSIT = Enum.filter(wallet_operations, fn operation -> operation.operation_type == "DEPOSIT" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)
    wallet_operations_WITHDRAWN = Enum.filter(wallet_operations, fn operation -> operation.operation_type == "WITHDRAWAL" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)
    form = to_form(%{}, as: "wallet_operation")

    {:ok, assign(socket, form: form), temporary_assigns: [form: form, show: false, editing: false, wallet_operations: wallet_operations, wallet_operations_DEPOSIT: wallet_operations_DEPOSIT, wallet_operations_WITHDRAWN: wallet_operations_WITHDRAWN]}
  end

  def handle_event("delete", params, socket) do
    Wallets.delete_operation(params["id"])
    {:noreply, assign(socket, %{})}
  end

  def handle_event("show_modal", _, socket) do
    form = to_form(%{}, as: "wallet_operation")
    {:noreply, assign(socket, form: form, show: true, editing: "false")}
  end

  def handle_event("hide_modal", _, socket) do
    {:noreply, assign(socket, show: "closed")}
  end

  def handle_event("edit", %{"id" => id}, socket) do
    operation = Repo.get(WalletOperation, id)
    wallet_op = WalletOperation.registration_changeset(operation, %{})
    form = to_form(wallet_op, as: "wallet_operation")

    {:noreply, assign(socket, form: form, editing: true, show: true)}
  end

  def handle_event("filter", params, socket) do
    wallet_operations = Wallets.get_wallet_history(socket.assigns.current_user.id)
    wallet_operations_filtered = case params["filter"] do
      "Ultimo Mes" -> Enum.filter(wallet_operations, fn operation -> Timex.diff(operation.inserted_at, Timex.now(), :months) <= 1 end)
      "Ultimo Semestre" -> Enum.filter(wallet_operations, fn operation -> Timex.diff(operation.inserted_at, Timex.now(), :months) <= 6 end)
      "Maiores saidas" -> Enum.sort_by(Enum.filter(wallet_operations, fn operation -> operation.operation_type == "WITHDRAWAL" end), & &1.amount, &>=/2)
      "Maiores entradas" -> Enum.sort_by(Enum.filter(wallet_operations, fn operation -> operation.operation_type == "DEPOSIT" end), & &1.amount, &>=/2)
    end

    wallet_operations_DEPOSIT = wallet_operations_filtered |> Enum.filter(fn operation -> operation.operation_type == "DEPOSIT" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)
    wallet_operations_WITHDRAWN = wallet_operations_filtered |> Enum.filter(fn operation -> operation.operation_type == "WITHDRAWAL" end)
      |> Enum.reduce(Decimal.new(0), fn operation, acc -> Decimal.add(acc, operation.amount) end)

    {:noreply, assign(socket, %{wallet_operations: wallet_operations, wallet_operations_DEPOSIT: wallet_operations_DEPOSIT, wallet_operations_WITHDRAWN: wallet_operations_WITHDRAWN})}
  end
end
