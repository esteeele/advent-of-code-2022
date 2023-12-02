defmodule ColourGame do
  def solve(red, green, blue) do
    instructions =
      File.read!("./lib/input.txt")
      |> String.split("\n")
      |> List.foldl(0, fn line, acc ->
        [game, data] =
          String.split(line, ":")
          |> Enum.map(fn part -> String.trim(part) end)

        games = String.split(data, ";") |> Enum.map(fn part -> String.trim(part) end)

        # part 1
        notPossible =
          List.foldl(games, true, fn gameValue, gameValid ->
            String.split(gameValue, ",")
            |> Enum.map(fn part -> String.trim(part) end)
            |> Enum.map(fn valueAndColour ->
              [value, colour] = String.split(valueAndColour, " ")

              intValue = Integer.parse(value) |> elem(0)

              isValid =
                case colour do
                  "red" -> intValue <= red
                  "green" -> intValue <= green
                  "blue" -> intValue <= blue
                  _ -> true
                end

              isValid
            end)
            |> List.foldl(gameValid, fn colourResult, acc -> colourResult and acc end)
          end)

        # part 2 build {'red' : 2} etc map
        minValues =
          List.foldl(games, %{}, fn gameValue, minColourValues ->
            String.split(gameValue, ",")
            |> Enum.map(fn part -> String.trim(part) end)
            |> List.foldl(minColourValues, fn valueAndColour, acc ->
              [value, colour] = String.split(valueAndColour, " ")
              intValue = Integer.parse(value) |> elem(0)

              Map.update(acc, colour, intValue, fn existingValue ->
                max(existingValue, intValue)
              end)
            end)
          end)

        acc + (Map.get(minValues, "red") * Map.get(minValues, "green") * Map.get(minValues, "blue"))
      end)
  end
end
