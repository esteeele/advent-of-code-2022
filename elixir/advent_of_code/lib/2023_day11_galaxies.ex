defmodule Day11Galaxies do
  def day11 do
    lines = parseInput()

    expandedRows =
      Enum.flat_map(lines, fn line ->
        if String.match?(line, ~r/#/) do
          [line]
        else
          [line, line]
        end
      end)

    row_length = String.length(hd(expandedRows))
    flatten_input = String.graphemes(Enum.join(expandedRows))
    total_length = length(flatten_input)

    mapped_cols =
      Enum.flat_map(Enum.to_list(0..(row_length - 1)), fn index ->
        column = Enum.take_every(Enum.take(flatten_input, index - total_length), row_length)

        if Enum.any?(column, fn point -> point == "#" end) do
          [column]
        else
          [column, column]
        end
      end)

    col_length = length(hd(mapped_cols))

    back_to_rows =
      Enum.map(Enum.to_list(0..(col_length - 1)), fn index ->
        Enum.map(mapped_cols, fn column ->
          Enum.at(column, index)
        end)
      end)

    # should be possible to do a shortcut and just work out how many along and how many down
    galaxies = d11_find_galaxy_positions(back_to_rows)

    iterate_through_galaxy_pairs(galaxies, [])
    |> List.flatten()
    |> Enum.sum()
  end

  def day11_part2 do
    input_grid =
      parseInput()
      |> Enum.map(fn line -> String.graphemes(line) end)

    galaxies = d11_find_galaxy_positions(input_grid)
    galaxies = day11_transform(input_grid, galaxies, :row)

    columns =
      d11_find_cols(List.flatten(input_grid), length(hd(input_grid)), 0, [])
      |> Enum.reverse()

    galaxies_adjusted = day11_transform(columns, galaxies, :col)

    iterate_through_galaxy_pairs(galaxies_adjusted, [])
    |> List.flatten()
    |> Enum.sum()
  end

  defp d11_find_galaxy_positions(grid) do
    Enum.reduce(grid, {[], {0, 0}}, fn row, {galaxy_positions, {_, y}} ->
      {galaxies_on_row, _} =
        Enum.reduce(row, {[], {0, y}}, fn position, {gr, {x, y}} ->
          if position == "#" do
            {[{x, y} | gr], {x + 1, y}}
          else
            {gr, {x + 1, y}}
          end
        end)

      {galaxy_positions ++ galaxies_on_row, {0, y + 1}}
    end)
    |> elem(0)
  end

  defp day11_transform(data_grid, galaxies, type) do
    Enum.reduce(Enum.reverse(data_grid), {length(hd(data_grid)) - 1, galaxies}, fn row,
                                                                                   {index,
                                                                                    galaxies} ->
      if Enum.all?(row, fn point -> point == "." end) do
        {index - 1,
         Enum.map(galaxies, fn {x, y} ->
           case type do
             :col ->
               if x > index do
                 {x + 999_999, y}
               else
                 {x, y}
               end

             :row ->
               if y > index do
                 {x, y + 999_999}
               else
                 {x, y}
               end
           end
         end)}
      else
        {index - 1, galaxies}
      end
    end)
    |> elem(1)
  end

  defp d11_find_cols(flat_input, row_size, index, columns) do
    if index >= row_size do
      columns
    else
      d11_find_cols(tl(flat_input), row_size, index + 1, [
        Enum.take_every(flat_input, row_size) | columns
      ])
    end
  end

  defp iterate_through_galaxy_pairs([], shortest_paths) do
    shortest_paths
  end

  defp iterate_through_galaxy_pairs([{g1_x, g1_y} | tail], shortest_paths) do
    res =
      Enum.map(tail, fn {g2_x, g2_y} ->
        dx = abs(g1_x - g2_x)
        dy = abs(g1_y - g2_y)
        dx + dy
      end)

    iterate_through_galaxy_pairs(tail, [res | shortest_paths])
  end

  defp parseInput() do
    File.read!("./lib/input.txt")
    |> String.split("\n", trim: true)
  end

  def day12 do
    parseInput()
    |> Enum.map(fn line ->
      [springs, list_lengths] = String.split(line, " ")

      lists_nums =
        String.graphemes(list_lengths)
        |> Enum.map(fn len -> String.to_integer(len) end)

      {String.graphemes(springs), lists_nums}
    end)
  end

end
