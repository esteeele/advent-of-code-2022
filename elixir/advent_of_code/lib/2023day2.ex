defmodule ColourGame do
  def solve(red, green, blue) do
    instructions =
      File.read!("./lib/input.txt")
      |> String.split("\n")
      |> List.foldl(0, fn line, acc ->
        [game, data] = splitAndTrim(line, ":")

        games = splitAndTrim(data, ";")

        # part 1
        notPossible =
          List.foldl(games, true, fn gameValue, gameValid ->
            splitAndTrim(gameValue, ",")
            |> Enum.map(fn valueAndColour ->
              [value, colour] = String.split(valueAndColour, " ")

              intValue = Integer.parse(value) |> elem(0)

              case colour do
                "red" -> intValue <= red
                "green" -> intValue <= green
                "blue" -> intValue <= blue
                _ -> true
              end
            end)
            |> List.foldl(gameValid, fn colourResult, acc -> colourResult and acc end)
          end)

        # part 2 build {'red' : 2} etc map
        minValues =
          List.foldl(games, %{}, fn gameValue, minColourValues ->
            splitAndTrim(gameValue, ",")
            |> List.foldl(minColourValues, fn valueAndColour, acc ->
              [value, colour] = splitAndTrim(valueAndColour, " ")
              intValue = Integer.parse(value) |> elem(0)

              Map.update(acc, colour, intValue, fn existingValue ->
                max(existingValue, intValue)
              end)
            end)
          end)

        acc + Map.get(minValues, "red") * Map.get(minValues, "green") * Map.get(minValues, "blue")
      end)
  end

  defp splitAndTrim(text, sep) do
    String.split(text, sep)
      |> Enum.map(fn part -> String.trim(part) end)
  end
end
