defmodule TodoList.User do
  def info(key), do: Riptide.query_path!(["user:info", key])

  def from_email(email) do
    case Riptide.query_path!(["email:user", email]) do
      nil -> {:error, :not_found}
      result -> {:ok, result}
    end
  end

  def password_valid?(user, password) do
    Bcrypt.verify_pass(password, Riptide.query_path!(["user:password", user]) || "")
  end

  def password_set(user, password) do
    result = Bcrypt.add_hash(password)
    Riptide.Mutation.merge(["user:password", user], result.password_hash)
  end
end
