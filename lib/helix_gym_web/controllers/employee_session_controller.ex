defmodule HelixGymWeb.EmployeeSessionController do
  use HelixGymWeb, :controller

  alias HelixGym.Accounts
  alias HelixGymWeb.EmployeeAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"employee" => employee_params}) do
    %{"document" => document, "password" => password} = employee_params

    if employee = Accounts.get_employee_by_document_and_password(document, password) do
      EmployeeAuth.log_in_employee(conn, employee, employee_params)
    else
      render(conn, "new.html", error_message: "Invalid document or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> EmployeeAuth.log_out_employee()
  end
end
