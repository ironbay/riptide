defmodule Riptide.UUID do
  @moduledoc """
  This module allows you to generate sortable Time UUIDs that can be used to control sorting order in Riptide stores. They have a time component that defaults to creation time as well as a random component.

  - Ascending UUIDs generated with `Riptide.UUID.ascending/0` will be sorted **oldest to newest** by their time component.
  - Descending UUIDs generated with `Riptide.UUID.descending/0` will be sorted **newest to oldest** by their time component.

  ## Usage

  Take the following data:
  ```json
  {
    "todo:info": {
      "0S1eOQ0kd0wnuUSWbDAu" => %{
        "text" => "My first todo!"
      }
    }
  }
  ```

  This entry uses an ascending UUID. This means if we create a new entry with an ascending UUID it will be inserted **below** the existing entry:

  ```json
  {
    "todo:info": {
      "0S1eOQ0kd0wnuUSWbDAu" => %{
        "text" => "My first todo!"
      },
      "0S1eP9y9x61XmeVoHzVM" => %{
        "text" => "My second todo!"
      }
    }
  }
  ```

  Now let's try it with descending UUIDs:

  ```json
  {
    "todo:info": {
      "zXyLafLmMB6Uac8NTOvA" => %{
        "text" => "My first todo!"
      }
    }
  }
  ```

  Adding another todo will insert it **above** the existing entry:

  ```json
  {
    "todo:info": {
      "zXyLaUMUDcB4zaVNCLM2" => %{
        "text" => "My second todo!"
      },
      "zXyLafLmMB6Uac8NTOvA" => %{
        "text" => "My first todo!"
      }
    }
  }
  ```

  The type of UUID that should be used depends on how your application is planning on using the data. For example, if your application typically loads the 10 newest created todos it makes sense to use descending UUIDs with the following query:

  ```
  Riptide.query_path ["todo:info"], %{limit: 10}
  ```

  Explore the functions in this module to see the additional options there are for creating UUIDs.

  """
  @forwards ~W(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @forwards_inverse @forwards |> Enum.with_index() |> Enum.into(%{})
  @backwards @forwards |> Enum.reverse()
  @backwards_inverse @backwards |> Enum.with_index() |> Enum.into(%{})
  @base Enum.count(@forwards)
  @length 8
  @total @length + 12

  @doc """
  Generate a UUID that can be sorted lexicographically from newest to oldest. The time component is set to the current time.
  """
  def descending(), do: descending(:os.system_time(:millisecond))

  @doc """
  Like `descending/0` with the ability to specify time component in milliseconds.
  """
  def descending(time), do: generate(time, @backwards, @backwards)

  @doc """
  Like `descending/1` with the random part zero filled. Useful for specifying ranges of UUIDs in queries.
  """
  def descending_uniform(time), do: generate(time, @backwards, ["0"])

  @doc """
  For a given descending UUID, extract the time component in milliseconds.
  """
  def descending_decode_time(key) do
    decode_time(@backwards_inverse, key)
  end

  @doc """
  Generate a UUID that can be sorted lexicographically from oldest to newest. The time component is set to the current time.
  """
  def ascending(), do: ascending(:os.system_time(:millisecond))

  @doc """
  Like `ascending/1` with the ability to specify time component.
  """
  def ascending(time), do: generate(time, @forwards, @forwards)

  @doc """
  Like `ascending/1` with the ability to specify time component.
  """
  def ascending_uniform(time), do: generate(time, @forwards, ["0"])

  @doc """
  For a given ascending UUID, extract the time component in milliseconds.
  """
  def ascending_decode_time(key) do
    decode_time(@forwards_inverse, key)
  end

  defp generate(time, range, random) do
    time
    |> generate(range, random, @total, [])
    |> Enum.join()
  end

  # Random Part
  defp generate(time, range, random, count, collect) when count > @length do
    collect = [Enum.random(random) | collect]
    generate(time, range, random, count - 1, collect)
  end

  # Time Part
  defp generate(time, range, random, count, collect) when count > 0 do
    n = time |> rem(@base)
    collect = [Enum.at(range, n) | collect]
    generate(div(time, @base), range, random, count - 1, collect)
  end

  defp generate(_time, _range, _random, _count, collect), do: collect

  defp decode_time(range, key) do
    decode_time(range, key, 0, 0)
  end

  defp decode_time(_, _, value, count) when count === @length do
    value
  end

  defp decode_time(range, <<head::utf8, tail::binary>>, collect, count) do
    value = Map.get(range, <<head>>)
    decode_time(range, tail, collect * @base + value, count + 1)
  end
end
