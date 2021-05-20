defmodule HelixGym.Repo.Migrations.CreateAdmAuthTables do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:adm) do
      add :credential, :string, null: false
      add :hashed_password, :string, null: false
      add :confirmed_at, :naive_datetime
      timestamps()
    end

    create unique_index(:adm, [:credential])

    create table(:adm_tokens) do
      add :adm_id, references(:adm, on_delete: :delete_all), null: false
      add :token, :binary, null: false
      add :context, :string, null: false
      add :sent_to, :string
      timestamps(updated_at: false)
    end

    create index(:adm_tokens, [:adm_id])
    create unique_index(:adm_tokens, [:context, :token])
  end
end
