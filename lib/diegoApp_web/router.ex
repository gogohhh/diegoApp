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
        {session_name, session_opts, route_opts} = DiegoAppWeb.Router..__options__(opts)
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

  def __options__(options) do
    live_socket_path = Keyword.get(options, :live_socket_path, "/live")

    metrics =
      case options[:metrics] do
        nil ->
          nil

        false ->
          :skip

        mod when is_atom(mod) ->
          {mod, :metrics}

        {mod, fun} when is_atom(mod) and is_atom(fun) ->
          {mod, fun}

        other ->
          raise ArgumentError,
                ":metrics must be a tuple with {Mod, fun}, " <>
                  "such as {MyAppWeb.Telemetry, :metrics}, got: #{inspect(other)}"
      end

    env_keys =
      case options[:env_keys] do
        nil ->
          nil

        keys when is_list(keys) ->
          keys

        other ->
          raise ArgumentError,
                ":env_keys must be a list of strings, got: " <> inspect(other)
      end

    home_app =
      case options[:home_app] do
        nil ->
          {"Dashboard", :phoenix_live_dashboard}

        {app_title, app_name} when is_binary(app_title) and is_atom(app_name) ->
          {app_title, app_name}

        other ->
          raise ArgumentError,
                ":home_app must be a tuple with a binary title and atom app, got: " <>
                  inspect(other)
      end

    metrics_history =
      case options[:metrics_history] do
        nil ->
          nil

        {module, function, args}
        when is_atom(module) and is_atom(function) and is_list(args) ->
          {module, function, args}

        other ->
          raise ArgumentError,
                ":metrics_history must be a tuple of {module, function, args}, got: " <>
                  inspect(other)
      end

    additional_pages =
      case options[:additional_pages] do
        nil ->
          []

        pages when is_list(pages) ->
          normalize_additional_pages(pages)

        other ->
          raise ArgumentError, ":additional_pages must be a keyword, got: " <> inspect(other)
      end

    request_logger_cookie_domain =
      case options[:request_logger_cookie_domain] do
        nil ->
          nil

        domain when is_binary(domain) ->
          domain

        :parent ->
          :parent

        other ->
          raise ArgumentError,
                ":request_logger_cookie_domain must be a binary or :parent atom, got: " <>
                  inspect(other)
      end

    request_logger_flag =
      case options[:request_logger] do
        nil ->
          true

        bool when is_boolean(bool) ->
          bool

        other ->
          raise ArgumentError,
                ":request_logger must be a boolean, got: " <> inspect(other)
      end

    request_logger = {request_logger_flag, request_logger_cookie_domain}

    ecto_repos = options[:ecto_repos]

    ecto_psql_extras_options =
      case options[:ecto_psql_extras_options] do
        nil ->
          []

        args ->
          unless Keyword.keyword?(args) and
                   args |> Keyword.values() |> Enum.all?(&Keyword.keyword?/1) do
            raise ArgumentError,
                  ":ecto_psql_extras_options must be a keyword where each value is a keyword, got: " <>
                    inspect(args)
          end

          args
      end

    ecto_mysql_extras_options =
      case options[:ecto_mysql_extras_options] do
        nil ->
          []

        args ->
          unless Keyword.keyword?(args) and
                   args |> Keyword.values() |> Enum.all?(&Keyword.keyword?/1) do
            raise ArgumentError,
                  ":ecto_mysql_extras_options must be a keyword where each value is a keyword, got: " <>
                    inspect(args)
          end

          args
      end

    csp_nonce_assign_key =
      case options[:csp_nonce_assign_key] do
        nil -> nil
        key when is_atom(key) -> %{img: key, style: key, script: key}
        %{} = keys -> Map.take(keys, [:img, :style, :script])
      end

    allow_destructive_actions = options[:allow_destructive_actions] || false

    session_args = [
      env_keys,
      home_app,
      allow_destructive_actions,
      metrics,
      metrics_history,
      additional_pages,
      request_logger,
      ecto_repos,
      ecto_psql_extras_options,
      ecto_mysql_extras_options,
      csp_nonce_assign_key
    ]

    {
      options[:live_session_name] || :live_dashboard,
      [
        session: {__MODULE__, :__session__, session_args},
        root_layout: {Phoenix.LiveDashboard.LayoutView, :root}
      ],
      [
        private: %{live_socket_path: live_socket_path, csp_nonce_assign_key: csp_nonce_assign_key},
        as: :live_dashboard
      ]
    }
  end

  defp normalize_additional_pages(pages) do
    Enum.map(pages, fn
      {path, module} when is_atom(path) and is_atom(module) ->
        {path, {module, []}}

      {path, {module, args}} when is_atom(path) and is_atom(module) ->
        {path, {module, args}}

      other ->
        msg =
          "invalid value in :additional_pages, " <>
            "must be a tuple {path, {module, args}} or {path, module}, where path " <>
            "is an atom and the module implements Phoenix.LiveDashboard.PageBuilder, got: "

        raise ArgumentError, msg <> inspect(other)
    end)
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
