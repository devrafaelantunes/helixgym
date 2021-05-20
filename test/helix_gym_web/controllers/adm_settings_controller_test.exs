defmodule HelixGymWeb.AdmSettingsControllerTest do
  use HelixGymWeb.ConnCase, async: true

  alias HelixGym.Administrators
  import HelixGym.AdministratorsFixtures

  setup :register_and_log_in_adm

  describe "GET /adm/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, Routes.adm_settings_path(conn, :edit))
      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
    end

    test "redirects if adm is not logged in" do
      conn = build_conn()
      conn = get(conn, Routes.adm_settings_path(conn, :edit))
      assert redirected_to(conn) == Routes.adm_session_path(conn, :new)
    end
  end

  describe "PUT /adm/settings (change password form)" do
    test "updates the adm password and resets tokens", %{conn: conn, adm: adm} do
      new_password_conn =
        put(conn, Routes.adm_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => valid_adm_password(),
          "adm" => %{
            "password" => "new valid password",
            "password_confirmation" => "new valid password"
          }
        })

      assert redirected_to(new_password_conn) == Routes.adm_settings_path(conn, :edit)
      assert get_session(new_password_conn, :adm_token) != get_session(conn, :adm_token)
      assert get_flash(new_password_conn, :info) =~ "Password updated successfully"
      assert Administrators.get_adm_by_email_and_password(adm.email, "new valid password")
    end

    test "does not update password on invalid data", %{conn: conn} do
      old_password_conn =
        put(conn, Routes.adm_settings_path(conn, :update), %{
          "action" => "update_password",
          "current_password" => "invalid",
          "adm" => %{
            "password" => "too short",
            "password_confirmation" => "does not match"
          }
        })

      response = html_response(old_password_conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "should be at least 12 character(s)"
      assert response =~ "does not match password"
      assert response =~ "is not valid"

      assert get_session(old_password_conn, :adm_token) == get_session(conn, :adm_token)
    end
  end

  describe "PUT /adm/settings (change email form)" do
    @tag :capture_log
    test "updates the adm email", %{conn: conn, adm: adm} do
      conn =
        put(conn, Routes.adm_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => valid_adm_password(),
          "adm" => %{"email" => unique_adm_email()}
        })

      assert redirected_to(conn) == Routes.adm_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "A link to confirm your email"
      assert Administrators.get_adm_by_email(adm.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, Routes.adm_settings_path(conn, :update), %{
          "action" => "update_email",
          "current_password" => "invalid",
          "adm" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "<h1>Settings</h1>"
      assert response =~ "must have the @ sign and no spaces"
      assert response =~ "is not valid"
    end
  end

  describe "GET /adm/settings/confirm_email/:token" do
    setup %{adm: adm} do
      email = unique_adm_email()

      token =
        extract_adm_token(fn url ->
          Administrators.deliver_update_email_instructions(%{adm | email: email}, adm.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the adm email once", %{conn: conn, adm: adm, token: token, email: email} do
      conn = get(conn, Routes.adm_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.adm_settings_path(conn, :edit)
      assert get_flash(conn, :info) =~ "Email changed successfully"
      refute Administrators.get_adm_by_email(adm.email)
      assert Administrators.get_adm_by_email(email)

      conn = get(conn, Routes.adm_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.adm_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, adm: adm} do
      conn = get(conn, Routes.adm_settings_path(conn, :confirm_email, "oops"))
      assert redirected_to(conn) == Routes.adm_settings_path(conn, :edit)
      assert get_flash(conn, :error) =~ "Email change link is invalid or it has expired"
      assert Administrators.get_adm_by_email(adm.email)
    end

    test "redirects if adm is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, Routes.adm_settings_path(conn, :confirm_email, token))
      assert redirected_to(conn) == Routes.adm_session_path(conn, :new)
    end
  end
end
