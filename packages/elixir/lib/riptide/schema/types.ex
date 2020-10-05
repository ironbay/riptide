defmodule Riptide.Schema.Type.Number do
  def validate(item, _opts) when is_number(item), do: :ok
  def validate(_item, _opts), do: {:error, :not_number}
end

defmodule Riptide.Schema.Type.String do
  def validate(item, _opts) when is_binary(item), do: :ok
  def validate(_item, _opts), do: {:error, :not_string}
end

defmodule Riptide.Schema.Type.Map do
  def validate(item, opts) when is_map(item) do
    {mod, sub_opts} =
      opts
      |> Keyword.get(:type, Riptide.Schema.Type.Any)
      |> Riptide.Schema.mod_opts()

    item
    |> Enum.map(fn {path, value} ->
      Riptide.Schema.validate_child([path], value, mod, sub_opts)
    end)
    |> List.flatten()
    |> case do
      [] ->
        :ok

      result ->
        {:error, result}
    end
  end

  def validate(_item, _opts), do: {:error, :not_map}
end

defmodule Riptide.Schema.Type.Any do
  def validate(_item, _opts), do: :ok
end

defmodule Riptide.Schema.Type.Enum do
  def validate(item, opts) do
    opts
    |> Keyword.get(:values, [])
    |> Enum.member?(item)
    |> case do
      true -> :ok
      false -> {:error, :invalid_value}
    end
  end
end

defmodule Riptide.Schema.Type.List do
  def validate(item, opts) do
    {mod, sub_opts} =
      opts
      |> Keyword.get(:type, Riptide.Schema.Type.Any)
      |> Riptide.Schema.mod_opts()

    item
    |> Stream.with_index()
    |> Enum.map(fn {value, index} ->
      Riptide.Schema.validate_child([index], value, mod, sub_opts)
    end)
    |> List.flatten()
    |> case do
      [] ->
        :ok

      result ->
        {:error, result}
    end
  end
end
