defmodule Tokens.Token do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :email, :string
    field :token, :string
  end

  def changeset(struct, params) do
    struct
    |> cast(params, [:email, :token])
    |> validate_required([:email])
  end

end
