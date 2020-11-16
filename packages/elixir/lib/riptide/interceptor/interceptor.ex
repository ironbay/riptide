defmodule Riptide.Next.Interceptor do
  defmacro mutation_before(input, body) do
    result = build(input)

    quote do
      unquote(result)
    end

    result
    |> Macro.to_string()
    |> IO.puts()

    quote do
      def trigger(layer) do
        vars = {}

        unquote(result)
        |> List.flatten()
      end
    end
  end

  defp build(nil) do
    quote do
      vars
    end
  end

  defp build({:%{}, _, children}) do
    quoted = Enum.map(children, fn child -> build(child) end)

    quote do
      unquote(quoted)
    end
  end

  defp build({key, _, children}), do: build({key, children})

  defp build({{_var, _, nil}, children}) do
    quote do
      for {key, value} <- layer do
        if is_map(layer) do
          vars = Tuple.append(vars, key)
          layer = value
          result = unquote(build(children))
          if Enum.all?(result, fn item -> item != nil end), do: result, else: []
        end
      end
    end
  end

  defp build({key, children = {:%{}, _, _}}) do
    quote do
      layer = Map.get(layer, unquote(key))

      if layer != nil do
        unquote(build(children))
      end
    end
  end

  defp build({key, {_, _, _}}) do
    quote do
      layer = Map.get(layer, unquote(key))

      if layer != nil do
        Tuple.append(vars, layer)
      end
    end
  end

  defp build({key, val}) do
    quote do
      layer = Map.get(layer, unquote(key))

      if layer == unquote(val) do
        []
      end
    end
  end
end

defmodule Riptide.Next.Interceptor.Sample do
  import Riptide.Next.Interceptor

  mutation_before %{
    merge: %{
      "user:info" => %{
        user => %{
          "name" => name,
          "nice" => "lol",
          "foo" => %{
            "lol" => lol
          }
        }
      }
    },
    delete: %{}
  } do
    IO.inspect({user, name})
  end

  def test() do
    trigger(%{
      merge: %{
        "user:info" => %{
          "dax" => %{
            "name" => "Dax",
            "nice" => "lol"
          },
          "bob" => %{
            "foo" => "Bob"
          }
        }
      },
      delete: %{}
    })
  end
end
