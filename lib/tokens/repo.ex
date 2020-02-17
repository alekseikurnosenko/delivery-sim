defmodule Tokens.Repo do
  use Ecto.Repo,
    otp_app: :delivery_sim,
    adapter: Ecto.Adapters.Postgres

  def add_token(email, token) do
    %Tokens.Token{}
    |> Tokens.Token.changeset(%{email: email, token: token})
    |> insert(on_conflict: [set: [token: token]], conflict_target: :email)
  end

  def get_token(email) do
    Tokens.Repo.get_by(Tokens.Token, email: email)
  end
end
