defmodule Tokens.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :email, :string, null: false, primary_key: true
      add :token, :text, null: true
    end
    create unique_index(:tokens, [:email])
  end
end
