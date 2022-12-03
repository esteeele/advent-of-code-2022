defmodule Elves do
  @spec calories :: any
  def calories do
    file = File.read!("/Users/ed/Documents/code/advent-of-code-2021/elixir/lib/2022-day-1/input.txt")
    split_file = file |> String.split("\n")

    max_calorie =
      List.foldl(split_file, [0], fn line, elf_list ->
        case line do
          "" ->
            [0 | elf_list]

          _ ->
            [calories_for_elf | tail] = elf_list
            calories_for_elf = calories_for_elf + (Integer.parse(line) |> elem(0))
            [calories_for_elf | tail]
        end
      end)
      |> Enum.sort(:desc)
      |> Enum.take(3)
      |> Enum.sum()

    IO.inspect(max_calorie)
  end
end
