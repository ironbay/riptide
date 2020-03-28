defmodule Riptide.UUID do
  @forwards ~W(0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z)
  @forwards_inverse @forwards |> Enum.with_index() |> Enum.into(%{})
  @backwards @forwards |> Enum.reverse()
  @backwards_inverse @backwards |> Enum.with_index() |> Enum.into(%{})
  @base Enum.count(@forwards)
  @length 8
  @total @length + 12

  def descending(), do: descending_from(:os.system_time(:millisecond))
  def descending_from(time), do: generate(time, @backwards, @backwards)
  def descending_from(time, :uniform), do: generate(time, @backwards, ["0"])

  def ascending(), do: ascending_from(:os.system_time(:millisecond))
  def ascending_from(time), do: generate(time, @forwards, @forwards)
  def ascending_from(time, :uniform), do: generate(time, @forwards, ["0"])

  def generate(time, range, random) do
    time
    |> generate(range, random, @total, [])
    |> Enum.join()
  end

  # Random Part
  def generate(time, range, random, count, collect) when count > @length do
    collect = [Enum.random(random) | collect]
    generate(time, range, random, count - 1, collect)
  end

  # Time Part
  def generate(time, range, random, count, collect) when count > 0 do
    n = time |> rem(@base)
    collect = [Enum.at(range, n) | collect]
    generate(div(time, @base), range, random, count - 1, collect)
  end

  def generate(_time, _range, _random, _count, collect), do: collect

  def ascending_decode_time(key) do
    decode_time(@forwards_inverse, key)
  end

  def descending_decode_time(key) do
    decode_time(@backwards_inverse, key)
  end

  def decode_time(range, key) do
    decode_time(range, key, 0, 0)
  end

  def decode_time(_, _, value, count) when count === @length do
    value
  end

  def decode_time(range, <<head::utf8, tail::binary>>, collect, count) do
    value = Map.get(range, <<head>>)
    decode_time(range, tail, collect * @base + value, count + 1)
  end
end
