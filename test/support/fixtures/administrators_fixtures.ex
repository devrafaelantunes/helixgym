defmodule HelixGym.AdministratorsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `HelixGym.Administrators` context.
  """

  def unique_adm_email, do: "adm#{System.unique_integer()}@example.com"
  def valid_adm_password, do: "hello world!"

  def valid_adm_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_adm_email(),
      password: valid_adm_password()
    })
  end

  def adm_fixture(attrs \\ %{}) do
    {:ok, adm} =
      attrs
      |> valid_adm_attributes()
      |> HelixGym.Administrators.register_adm()

    adm
  end

  def extract_adm_token(fun) do
    {:ok, captured} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token, _] = String.split(captured.body, "[TOKEN]")
    token
  end
end
