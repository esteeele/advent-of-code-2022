defmodule TimeIsAFlatCucle do
  def day14 do
    lines =
      parseInput()
      |> Enum.map(fn line -> String.graphemes(line) end)

    part1 =
      zip_to_list(lines)
      |> Enum.map(fn column ->
        day14_iterate_rocks(column, {[], column, []})
      end)
      |> zip_to_list()

    res = day14_part2(lines, 1000000000, 0, %{})
    IO.inspect(res)

    day14_calculateResult(part1)
  end

  defp day14_part2(input, repeats, iteration, lookup_map) do
    {next_iter, is_loop} =
      if Map.has_key?(lookup_map, input) do
        previous_appearence = Map.get(lookup_map, input)
        IO.puts("Found loop at #{iteration} previously at #{previous_appearence}")
        loop_size = iteration - previous_appearence
        jump = previous_appearence + (div(repeats - previous_appearence, loop_size)) * loop_size
        IO.puts("Jumping to #{jump}")
        { jump, true }
      else
        { iteration + 1, false }
      end

    if is_loop do
      do_final_cycle(input, repeats, next_iter)
    else
      updated_input = do_cycle(input)

      lookup_map = Map.put(lookup_map, input, iteration)
      day14_part2(updated_input, repeats, next_iter, lookup_map)
    end
  end

  #probably a better way to do this, but complete the last few iterations of the loop
  defp do_final_cycle(input, repeats, iteration) do
    if iteration < repeats do
      updated_input = do_cycle(input)
      result = day14_calculateResult(input |> Enum.reverse())
      IO.puts("Result #{result |> elem(0)} for iteration: #{iteration}")
      do_final_cycle(updated_input, repeats, iteration + 1)
    else
      day14_calculateResult(input |> Enum.reverse())
    end
  end

  defp zip_to_list(input) do
    Enum.zip(input)
    |> Enum.map(&Tuple.to_list/1)
  end

  defp do_cycle(input) do
    zip_to_list(input)
    |> Enum.map(fn column ->
      day14_iterate_rocks(column, {[], column, []})
    end)
    |> map_cols_to_rows()
    |> Enum.map(fn line -> day14_iterate_rocks(line, {[], line, []}) end) #east
    |> Enum.map(&Enum.reverse/1)
    |> zip_to_list() #south
    |> Enum.map(&Enum.reverse/1)
    |> Enum.map(fn line ->
      day14_iterate_rocks(line, {[], line, []})
    end)
    |> map_cols_to_rows() #west
    |> Enum.reverse()
    |> Enum.map(&Enum.reverse/1)
    |> Enum.map(fn line -> day14_iterate_rocks(line, {[], line, []}) end)
  end

  defp map_cols_to_rows(cols) do
    Enum.map(cols, &Enum.reverse/1)
    |> zip_to_list()
  end

  # expects upside down columns
  defp day14_calculateResult(fallen_rocks) do
    Enum.reduce(fallen_rocks, {0, 1}, fn grouped_row, {sum, multiplier} ->
      row_sum = Enum.count(grouped_row, fn item -> item == "O" end) * multiplier
      {sum + row_sum, multiplier + 1}
    end)
  end

  defp day14_iterate_rocks(column, {new_list, old_list, air_gaps}) do
    case column do
      [] ->
        air_gaps ++ new_list

      _ ->
        updated_acc = map_rock(hd(column), {new_list, old_list, air_gaps})
        day14_iterate_rocks(tl(column), updated_acc)
    end
  end

  defp map_rock(rock, {new_list, old_list, air_gaps}) do
    case rock do
      "O" -> {[rock | new_list], tl(old_list), air_gaps}
      "#" -> {[rock] ++ air_gaps ++ new_list, tl(old_list), []}
      "." -> {new_list, tl(old_list), [rock | air_gaps]}
    end
  end

  defp parseInput() do
    File.read!("./lib/input.txt")
    |> String.split("\n", trim: true)
  end
end
