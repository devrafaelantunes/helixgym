defmodule HelixGymWeb.AdmConfirmationControllerTest do
  use HelixGymWeb.ConnCase, async: true

  alias HelixGym.Administrators
  alias HelixGym.Repo
  import HelixGym.AdministratorsFixtures

  setup do
    %{adm: adm_fixture()}
  end

  describe "GET /adms/confirm" do
    test "renders the confirmation page", %{conn: conn} do
      conn = get(conn, Routes.adm_confirmation_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Resend confirmation instructions</h1>"
    end
  end

  describe "POST /adms/confirm" do
    @tag :capture_log
    test "sends a new confirmation token", %{conn: conn, adm: adm} do
      conn =
        post(conn, Routes.adm_confirmation_path(conn, :create), %{
          "adm" => %{"email" => adm.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Administrators.AdmToken, adm_id: adm.id).context == "confirm"
    end

    test "does not send confirmation token if Adm is confirmed", %{conn: conn, adm: adm} do
      Repo.update!(Administrators.Adm.confirm_changeset(adm))

      conn =
        post(conn, Routes.adm_confirmation_path(conn, :create), %{
          "adm" => %{"email" => adm.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      refute Repo.get_by(Administrators.AdmToken, adm_id: adm.id)
    end

    test "does not send confirmation token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.adm_confirmation_path(conn, :create), %{
          "adm" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Administrators.AdmToken) == []
    end
  end

  describe "GET /adms/confirm/:token" do
    test "confirms the given token once", %{conn: conn, adm: adm} do
      token =
        extract_adm_token(fn url ->
          Administrators.deliver_adm_confirmation_instructions(adm, url)
        end)

      conn = get(conn, Routes.adm_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "Adm confirmed successfully"
      assert Administrators.get_adm!(adm.id).confirmed_at
      refute get_session(conn, :adm_token)
      assert Repo.all(Administrators.AdmToken) == []

      # When not logged in
      conn = get(conn, Routes.adm_confirmation_path(conn, :confirm, token))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Adm confirmation link is invalid or it has expired"

      # When logged in
      conn =
        build_conn()
        |> log_in_adm(adm)
        |> get(Routes.adm_confirmation_path(conn, :confirm, token))

      assert redirected_to(conn) == "/"
      refute get_flash(conn, :error)
    end

    test "does not confirm email with invalid token", %{conn: conn, adm: adm} do
      conn = get(conn, Routes.adm_confirmation_path(conn, :confirm, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Adm confirmation link is invalid or it has expired"
      refute Administrators.get_adm!(adm.id).confirmed_at
    end
  end
end
