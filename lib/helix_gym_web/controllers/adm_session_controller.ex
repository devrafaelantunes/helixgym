defmodule HelixGymWeb.AdmSessionController do
  use HelixGymWeb, :controller

  alias HelixGym.Administrators
  alias HelixGymWeb.AdmAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"adm" => adm_params}) do
    %{"credential" => credential, "password" => password} = adm_params

    if adm = Administrators.get_adm_by_credential_and_password(credential, password) do
      AdmAuth.log_in_adm(conn, adm, adm_params)
    else
      render(conn, "new.html", error_message: "Invalid credential or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdmAuth.log_out_adm()
  end

end
