defmodule Riptide.Test.Data do
  def clean_tank(),
    do:
      {"001",
       %{
         "key" => "001",
         "name" => "Clean the shark tank"
       }}

  def pet_hammerhead(),
    do:
      {"002",
       %{
         "key" => "002",
         "name" => "Pet Sledge, the hammerhead shark"
       }}
end
