defmodule Rucksacks do
  def solve do
    file =
      File.read!("./lib/input.txt")

    part1 =
      file
      |> String.split("\n")
      |> Enum.map(fn line ->
        line_length = div(String.length(line), 2)
        parts = String.split_at(line, line_length)

        chunk1_freq =
          String.graphemes(parts |> elem(0))
          |> Enum.frequencies()
          |> Map.keys()

        chunk2_freq =
          parts
          |> elem(1)
          |> String.graphemes()
          |> Enum.frequencies()
          |> Map.keys()
          |> MapSet.new()

        Enum.filter(chunk1_freq, fn k ->
          MapSet.member?(chunk2_freq, k)
        end)
        |> Enum.map(fn letter ->
          find_score_from_letter(letter)
        end)
        |> Enum.sum()
      end)
      |> Enum.sum()

    IO.inspect(part1)

    part2 =
      file
      |> String.split("\n")
      |> Enum.chunk_every(3)
      |> Enum.map(fn grouped_lines ->
        IO.inspect(grouped_lines)

        Enum.reduce(grouped_lines, %{}, fn line, acc ->
          IO.inspect(acc)
          String.graphemes(line)
          |> Enum.frequencies()
          |> Map.keys()
          |> Enum.filter(fn key -> acc == %{} or Map.has_key?(acc, key) end)
          |> List.foldl(acc, fn key, map -> Map.update(map, key, 1, fn existing_val -> existing_val + 1 end)
        end)
        end)
        |> Map.filter(fn {_key, value} -> value >= 3 end)
        |> Map.keys()
        |> Enum.map(fn letter -> find_score_from_letter(letter) end)
        |> Enum.sum()
      end)
      |> Enum.sum()
  end

  defp find_score_from_letter(letter) do
    String.to_charlist(letter)
    |> hd()
    |> find_score()
  end

  defp find_score(ascii_val) do
    if ascii_val >= 65 and ascii_val <= 90 do
      ascii_val - 38
    else
      ascii_val - 96
    end
  end
end
