defmodule Riptide.Test.Data do
  def clean_tank(),
    do:
      {"001",
       %{
         "key" => "001",
         "name" => "Clean the shark tank",
         "times" => %{
           "created" => :os.system_time(:millisecond)
         }
       }}

  def pet_hammerhead(),
    do:
      {"002",
       %{
         "key" => "002",
         "name" => "Pet Sledge, the hammerhead shark",
         "times" => %{
           "created" => :os.system_time(:millisecond)
         }
       }}
end
