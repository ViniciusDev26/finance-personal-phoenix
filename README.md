# Finance

Aplicação web de finanças pessoais em **Elixir + Phoenix LiveView**. Cada usuário tem uma carteira e registra suas entradas e saídas para acompanhar o saldo.

## Funcionalidades

- **Autenticação completa** (gerada com `phx.gen.auth`): cadastro, login, confirmação de e-mail, recuperação de senha e configurações da conta.
- **Carteira por usuário**: criada automaticamente no primeiro acesso, com saldo inicial `0` e moeda `BRL` (o schema aceita `BRL`, `USD` e `EUR`).
- **Movimentações**: cadastrar, editar e excluir entradas (`DEPOSIT`) e saídas (`WITHDRAWAL`), com nome, detalhes e valor. Ao excluir uma movimentação, o saldo é ajustado.
- **Totais**: o painel mostra o total de entradas e o total de saídas.
- **Filtros**: último mês, último semestre, maiores saídas e maiores entradas.

## Stack

| Camada         | Tecnologia                                  |
| -------------- | ------------------------------------------- |
| Linguagem      | Elixir ~> 1.14                              |
| Web            | Phoenix 1.7 + LiveView 1.0                  |
| Banco de dados | PostgreSQL (via Ecto)                       |
| Frontend       | Tailwind CSS, esbuild, Heroicons            |
| Servidor HTTP  | Bandit                                      |
| Outros         | Bcrypt (senhas), Swoosh (e-mails), Timex    |

## Pré-requisitos

- Elixir 1.14+ e Erlang/OTP
- Docker e Docker Compose (para subir o PostgreSQL), ou um PostgreSQL local

## Como rodar

1. Suba o banco de dados:

   ```bash
   docker compose up -d
   ```

   Isso inicia um PostgreSQL em `localhost:5432` com usuário/senha `postgres`/`postgres` e banco `finance`, que é a configuração usada em `config/dev.exs`.

2. Instale as dependências, crie o banco, rode as migrations e compile os assets:

   ```bash
   mix setup
   ```

3. Inicie o servidor:

   ```bash
   mix phx.server
   # ou, com um shell interativo:
   iex -S mix phx.server
   ```

4. Acesse [http://localhost:4000](http://localhost:4000), crie uma conta e comece a registrar suas movimentações.

Em desenvolvimento ficam disponíveis:

- `/dev/dashboard`: Phoenix LiveDashboard
- `/dev/mailbox`: caixa de entrada local do Swoosh, onde aparecem os e-mails de confirmação e de recuperação de senha

## Estrutura do projeto

```
lib/
├── finance/
│   ├── accounts/            # Usuários, tokens e notificações por e-mail
│   ├── accounts.ex          # Contexto de contas
│   ├── wallets/
│   │   ├── wallet.ex            # Schema da carteira (saldo, moeda)
│   │   └── wallet-operation.ex  # Schema das movimentações
│   └── wallet.ex            # Contexto Finance.Wallets (regras de negócio)
└── finance_web/
    ├── controllers/
    │   └── wallet_controller.ex # POST/PUT /wallet (criar/editar movimentação)
    ├── live/
    │   ├── wallet/home_live.ex  # Tela principal (lista, totais, filtros)
    │   └── user_*_live.ex       # Telas de autenticação
    └── router.ex
priv/repo/migrations/          # Tabelas users, wallet e wallet_operations
```

## Modelo de dados

- **users**: usuários da aplicação.
- **wallet**: `balance` (decimal 10,2), `currency` e `user_id`.
- **wallet_operations**: `name`, `details`, `amount` (decimal 10,2), `operation_type` (enum Postgres `DEPOSIT` | `WITHDRAWAL`) e `wallet_id`.

## Comandos úteis

| Comando           | Descrição                                          |
| ----------------- | -------------------------------------------------- |
| `mix setup`       | Instala dependências, prepara o banco e os assets  |
| `mix phx.server`  | Inicia o servidor em `localhost:4000`              |
| `mix test`        | Roda a suíte de testes                             |
| `mix ecto.reset`  | Apaga e recria o banco de dados                    |
| `mix format`      | Formata o código                                   |
