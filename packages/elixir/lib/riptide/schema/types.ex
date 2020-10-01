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
      case Keyword.get(opts, :type) do
        nil -> {Riptide.Scheduler.Schema.Any, []}
        {mod, opts} -> {mod, opts}
        mod -> {mod, []}
      end

    Enum.map(item, fn {path, value} ->
      Riptide.Schema.validate_child(path, value, mod, sub_opts)
    end)
  end

  def validate(_item, _opts), do: {:error, :not_map}
end

defmodule Riptide.Schema.Type.Any do
  def validate(_item, _opts), do: :ok
end
