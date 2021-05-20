defmodule HelixGymWeb.AdmAuthTest do
  use HelixGymWeb.ConnCase, async: true

  alias HelixGym.Administrators
  alias HelixGymWeb.AdmAuth
  import HelixGym.AdministratorsFixtures

  @remember_me_cookie "_helix_gym_web_adm_remember_me"

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, HelixGymWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    %{adm: adm_fixture(), conn: conn}
  end

  describe "log_in_adm/3" do
    test "stores the adm token in the session", %{conn: conn, adm: adm} do
      conn = AdmAuth.log_in_adm(conn, adm)
      assert token = get_session(conn, :adm_token)
      assert get_session(conn, :live_socket_id) == "adm_sessions:#{Base.url_encode64(token)}"
      assert redirected_to(conn) == "/"
      assert Administrators.get_adm_by_session_token(token)
    end

    test "clears everything previously stored in the session", %{conn: conn, adm: adm} do
      conn = conn |> put_session(:to_be_removed, "value") |> AdmAuth.log_in_adm(adm)
      refute get_session(conn, :to_be_removed)
    end

    test "redirects to the configured path", %{conn: conn, adm: adm} do
      conn = conn |> put_session(:adm_return_to, "/hello") |> AdmAuth.log_in_adm(adm)
      assert redirected_to(conn) == "/hello"
    end

    test "writes a cookie if remember_me is configured", %{conn: conn, adm: adm} do
      conn = conn |> fetch_cookies() |> AdmAuth.log_in_adm(adm, %{"remember_me" => "true"})
      assert get_session(conn, :adm_token) == conn.cookies[@remember_me_cookie]

      assert %{value: signed_token, max_age: max_age} = conn.resp_cookies[@remember_me_cookie]
      assert signed_token != get_session(conn, :adm_token)
      assert max_age == 5_184_000
    end
  end

  describe "logout_adm/1" do
    test "erases session and cookies", %{conn: conn, adm: adm} do
      adm_token = Administrators.generate_adm_session_token(adm)

      conn =
        conn
        |> put_session(:adm_token, adm_token)
        |> put_req_cookie(@remember_me_cookie, adm_token)
        |> fetch_cookies()
        |> AdmAuth.log_out_adm()

      refute get_session(conn, :adm_token)
      refute conn.cookies[@remember_me_cookie]
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
      refute Administrators.get_adm_by_session_token(adm_token)
    end

    test "broadcasts to the given live_socket_id", %{conn: conn} do
      live_socket_id = "adm_sessions:abcdef-token"
      HelixGymWeb.Endpoint.subscribe(live_socket_id)

      conn
      |> put_session(:live_socket_id, live_socket_id)
      |> AdmAuth.log_out_adm()

      assert_receive %Phoenix.Socket.Broadcast{
        event: "disconnect",
        topic: "adm_sessions:abcdef-token"
      }
    end

    test "works even if adm is already logged out", %{conn: conn} do
      conn = conn |> fetch_cookies() |> AdmAuth.log_out_adm()
      refute get_session(conn, :adm_token)
      assert %{max_age: 0} = conn.resp_cookies[@remember_me_cookie]
      assert redirected_to(conn) == "/"
    end
  end

  describe "fetch_current_adm/2" do
    test "authenticates adm from session", %{conn: conn, adm: adm} do
      adm_token = Administrators.generate_adm_session_token(adm)
      conn = conn |> put_session(:adm_token, adm_token) |> AdmAuth.fetch_current_adm([])
      assert conn.assigns.current_adm.id == adm.id
    end

    test "authenticates adm from cookies", %{conn: conn, adm: adm} do
      logged_in_conn =
        conn |> fetch_cookies() |> AdmAuth.log_in_adm(adm, %{"remember_me" => "true"})

      adm_token = logged_in_conn.cookies[@remember_me_cookie]
      %{value: signed_token} = logged_in_conn.resp_cookies[@remember_me_cookie]

      conn =
        conn
        |> put_req_cookie(@remember_me_cookie, signed_token)
        |> AdmAuth.fetch_current_adm([])

      assert get_session(conn, :adm_token) == adm_token
      assert conn.assigns.current_adm.id == adm.id
    end

    test "does not authenticate if data is missing", %{conn: conn, adm: adm} do
      _ = Administrators.generate_adm_session_token(adm)
      conn = AdmAuth.fetch_current_adm(conn, [])
      refute get_session(conn, :adm_token)
      refute conn.assigns.current_adm
    end
  end

  describe "redirect_if_adm_is_authenticated/2" do
    test "redirects if adm is authenticated", %{conn: conn, adm: adm} do
      conn = conn |> assign(:current_adm, adm) |> AdmAuth.redirect_if_adm_is_authenticated([])
      assert conn.halted
      assert redirected_to(conn) == "/"
    end

    test "does not redirect if adm is not authenticated", %{conn: conn} do
      conn = AdmAuth.redirect_if_adm_is_authenticated(conn, [])
      refute conn.halted
      refute conn.status
    end
  end

  describe "require_authenticated_adm/2" do
    test "redirects if adm is not authenticated", %{conn: conn} do
      conn = conn |> fetch_flash() |> AdmAuth.require_authenticated_adm([])
      assert conn.halted
      assert redirected_to(conn) == Routes.adm_session_path(conn, :new)
      assert get_flash(conn, :error) == "You must log in to access this page."
    end

    test "stores the path to redirect to on GET", %{conn: conn} do
      halted_conn =
        %{conn | request_path: "/foo", query_string: ""}
        |> fetch_flash()
        |> AdmAuth.require_authenticated_adm([])

      assert halted_conn.halted
      assert get_session(halted_conn, :adm_return_to) == "/foo"

      halted_conn =
        %{conn | request_path: "/foo", query_string: "bar=baz"}
        |> fetch_flash()
        |> AdmAuth.require_authenticated_adm([])

      assert halted_conn.halted
      assert get_session(halted_conn, :adm_return_to) == "/foo?bar=baz"

      halted_conn =
        %{conn | request_path: "/foo?bar", method: "POST"}
        |> fetch_flash()
        |> AdmAuth.require_authenticated_adm([])

      assert halted_conn.halted
      refute get_session(halted_conn, :adm_return_to)
    end

    test "does not redirect if adm is authenticated", %{conn: conn, adm: adm} do
      conn = conn |> assign(:current_adm, adm) |> AdmAuth.require_authenticated_adm([])
      refute conn.halted
      refute conn.status
    end
  end
end
