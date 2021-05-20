defmodule HelixGym.Administrators do
  @moduledoc """
  The Administrators context.
  """

  import Ecto.Query, warn: false
  alias HelixGym.Repo
  alias HelixGym.Administrators.{Adm, AdmToken}

  ## Database getters

  @doc """
  Gets a adm by credential.

  ## Examples

      iex> get_adm_by_credential("foo@example.com")
      %Adm{}

      iex> get_adm_by_credential("unknown@example.com")
      nil

  """
  def get_adm_by_credential(credential) when is_binary(credential) do
    Repo.get_by(Adm, credential: credential)
  end

  def change_adm_registration(%Adm{} = adm, attrs \\ %{}) do
    Adm.registration_changeset(adm, attrs, hash_password: false)
  end

  @doc """
  Gets a adm by credential and password.

  ## Examples

      iex> get_adm_by_credential_and_password("foo@example.com", "correct_password")
      %Adm{}

      iex> get_adm_by_credential_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_adm_by_credential_and_password(credential, password)
      when is_binary(credential) and is_binary(password) do
    adm = Repo.get_by(Adm, credential: credential)
    if Adm.valid_password?(adm, password), do: adm
  end

  @doc """
  Gets a single adm.

  Raises `Ecto.NoResultsError` if the Adm does not exist.

  ## Examples

      iex> get_adm!(123)
      %Adm{}

      iex> get_adm!(456)
      ** (Ecto.NoResultsError)

  """
  def get_adm!(id), do: Repo.get!(Adm, id)

  ## Adm registration

  @doc """
  Registers a adm.

  ## Examples

      iex> register_adm(%{field: value})
      {:ok, %Adm{}}

      iex> register_adm(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  """
  def register_adm(attrs) do
    %Adm{}
    |> Adm.registration_changeset(attrs)
    |> Repo.insert()
  end


  ## Session

  @doc """
  Generates a session token.
  """
  def generate_adm_session_token(adm) do
    {token, adm_token} = AdmToken.build_session_token(adm)
    Repo.insert!(adm_token)
    token
  end

  @doc """
  Gets the adm with the given signed token.
  """
  def get_adm_by_session_token(token) do
    {:ok, query} = AdmToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(AdmToken.token_and_context_query(token, "session"))
    :ok
  end
end
