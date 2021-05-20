defmodule HelixGymWeb.Router do
  use HelixGymWeb, :router

  import HelixGymWeb.EmployeeAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {HelixGymWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_employee
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HelixGymWeb do
    pipe_through :browser

    live "/", PageLive, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HelixGymWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: HelixGymWeb.Telemetry
    end
  end

  ## Authentication routes

  scope "/", HelixGymWeb do
    pipe_through [:browser, :redirect_if_employee_is_authenticated]

    get "/employees/register", EmployeeRegistrationController, :new
    post "/employees/register", EmployeeRegistrationController, :create
    get "/employees/log_in", EmployeeSessionController, :new
    post "/employees/log_in", EmployeeSessionController, :create
    get "/employees/reset_password", EmployeeResetPasswordController, :new
    post "/employees/reset_password", EmployeeResetPasswordController, :create
    get "/employees/reset_password/:token", EmployeeResetPasswordController, :edit
    put "/employees/reset_password/:token", EmployeeResetPasswordController, :update
  end

  scope "/", HelixGymWeb do
    pipe_through [:browser, :require_authenticated_employee]

    get "/employees/settings", EmployeeSettingsController, :edit
    put "/employees/settings", EmployeeSettingsController, :update
    get "/employees/settings/confirm_email/:token", EmployeeSettingsController, :confirm_email
  end

  scope "/", HelixGymWeb do
    pipe_through [:browser]

    delete "/employees/log_out", EmployeeSessionController, :delete
    get "/employees/confirm", EmployeeConfirmationController, :new
    post "/employees/confirm", EmployeeConfirmationController, :create
    get "/employees/confirm/:token", EmployeeConfirmationController, :confirm
  end
end
