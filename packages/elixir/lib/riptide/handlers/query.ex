defmodule Riptide.Handler.Query do
  @moduledoc false
  use Riptide.Handler

  def handle_call("riptide.query", query, state) do
    case Riptide.query(query, state) do
      {:error, msg} ->
        {:error, msg, state}

      {:ok, result} ->
        layers = Riptide.Query.flatten(query)

        Enum.each(layers, fn {path, opts} ->
          if opts[:subscribe] === true do
            Riptide.Subscribe.watch(path)
          end
        end)

        {:reply,
         layers
         |> Enum.reduce(Riptide.Mutation.new(result), fn {path, opts}, collect ->
           opts
           |> Map.keys()
           |> Enum.any?(fn key -> Enum.member?([:limit, :min, :max], key) end)
           |> case do
             true -> Riptide.Mutation.delete(collect, path)
             false -> collect
           end
         end), state}
    end
  end
end
