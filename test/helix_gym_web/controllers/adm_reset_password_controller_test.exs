defmodule HelixGymWeb.AdmResetPasswordControllerTest do
  use HelixGymWeb.ConnCase, async: true

  alias HelixGym.Administrators
  alias HelixGym.Repo
  import HelixGym.AdministratorsFixtures

  setup do
    %{adm: adm_fixture()}
  end

  describe "GET /adm/reset_password" do
    test "renders the reset password page", %{conn: conn} do
      conn = get(conn, Routes.adm_reset_password_path(conn, :new))
      response = html_response(conn, 200)
      assert response =~ "<h1>Forgot your password?</h1>"
    end
  end

  describe "POST /adm/reset_password" do
    @tag :capture_log
    test "sends a new reset password token", %{conn: conn, adm: adm} do
      conn =
        post(conn, Routes.adm_reset_password_path(conn, :create), %{
          "adm" => %{"email" => adm.email}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.get_by!(Administrators.AdmToken, adm_id: adm.id).context == "reset_password"
    end

    test "does not send reset password token if email is invalid", %{conn: conn} do
      conn =
        post(conn, Routes.adm_reset_password_path(conn, :create), %{
          "adm" => %{"email" => "unknown@example.com"}
        })

      assert redirected_to(conn) == "/"
      assert get_flash(conn, :info) =~ "If your email is in our system"
      assert Repo.all(Administrators.AdmToken) == []
    end
  end

  describe "GET /adm/reset_password/:token" do
    setup %{adm: adm} do
      token =
        extract_adm_token(fn url ->
          Administrators.deliver_adm_reset_password_instructions(adm, url)
        end)

      %{token: token}
    end

    test "renders reset password", %{conn: conn, token: token} do
      conn = get(conn, Routes.adm_reset_password_path(conn, :edit, token))
      assert html_response(conn, 200) =~ "<h1>Reset password</h1>"
    end

    test "does not render reset password with invalid token", %{conn: conn} do
      conn = get(conn, Routes.adm_reset_password_path(conn, :edit, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end

  describe "PUT /adm/reset_password/:token" do
    setup %{adm: adm} do
      token =
        extract_adm_token(fn url ->
          Administrators.deliver_adm_reset_password_instructions(adm, url)
        end)

      %{token: token}
    end

    test "resets password once", %{conn: conn, adm: adm, token: token} do
      conn =
        put(conn, Routes.adm_reset_password_path(conn, :update, token), %{
          "adm" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(conn) == Routes.adm_session_path(conn, :new)
      refute get_session(conn, :adm_token)
      assert get_flash(conn, :info) =~ "Password reset successfully"
      assert Administrators.get_adm_by_email_and_password(adm.email, "new valid password")
    end

    test "does not reset password on invalid data", %{conn: conn, token: token} do
      conn =
        put(conn, Routes.adm_reset_password_path(conn, :update, token), %{
          "adm" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Reset password</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
    end

    test "does not reset password with invalid token", %{conn: conn} do
      conn = put(conn, Routes.adm_reset_password_path(conn, :update, "oops"))
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "Reset password link is invalid or it has expired"
    end
  end
end
