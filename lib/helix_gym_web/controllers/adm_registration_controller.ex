defmodule HelixGymWeb.AdmRegistrationController do
  use HelixGymWeb, :controller

  alias HelixGym.Administrators
  alias HelixGym.Administrators.Adm
  alias HelixGymWeb.AdmAuth

  def new(conn, _params) do
    changeset = Administrators.change_adm_registration(%Adm{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"adm" => adm_params}) do
    case Administrators.register_adm(adm_params) do
      {:ok, adm} ->
        conn
        |> put_flash(:info, "Adm created successfully.")
        |> AdmAuth.log_in_adm(adm)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
