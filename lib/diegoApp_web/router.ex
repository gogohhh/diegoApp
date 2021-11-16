defmodule DiegoAppWeb.Router do
  use DiegoAppWeb, :router

  #pipeline :browser do
  #  plug :accepts, ["html"]
  #  plug :fetch_session
  #  plug :fetch_live_flash
  #  plug :put_root_layout, {DiegoAppWeb.LayoutView, :root}
  #  plug :protect_from_forgery
  #  plug :put_secure_browser_headers
  #end

  defmacro live_diegoApp(path, opts \\ []) do
    quote bind_quoted: binding() do
      scope path, alias: false, as: false do
        {session_name, session_opts, route_opts} = DiegoAppWeb.Router
        import DiegoAppWeb.Router, only: [live: 4, live_session: 3]

        live_session session_name, session_opts do
          # All helpers are public contracts and cannot be changed
          live "/", DiegoAppWeb.PageLive, :home, route_opts
          live "/:page", DiegoAppWeb.PageLive, :page, route_opts
          live "/:node/:page", DiegoAppWeb.PageLive, :page, route_opts
        end
      end
    end
  end

  #pipeline :api do
  #  plug :accepts, ["json"]
  #end

  #scope "/", DiegoAppWeb do
  #  pipe_through :browser
#
  #  live "/", PageLive, :index
  #end

  # Other scopes may use custom stacks.
  # scope "/api", DiegoAppWeb do
  #   pipe_through :api
  # end
end
