defmodule Finance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FinanceWeb.Telemetry,
      Finance.Repo,
      {DNSCluster, query: Application.get_env(:finance, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Finance.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Finance.Finch},
      # Start a worker by calling: Finance.Worker.start_link(arg)
      # {Finance.Worker, arg},
      # Start to serve requests, typically the last entry
      FinanceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Finance.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FinanceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
