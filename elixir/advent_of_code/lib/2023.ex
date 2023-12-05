defmodule Advent2023 do
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

  def day3() do
    File.read!("./lib/input.txt")
    |> String.split("\n")
    |> Enum.reduce(0, fn line, acc ->
      [_card, numbers] = splitAndTrim(line, ":")
      winners = mapCardLineToWinningNumbers(numbers)

      case winners do
        [] -> acc
        _ -> acc + Integer.pow(2, length(winners) - 1)
      end
    end)
  end

  def day3Part2 do
    cardScoreLookup =
      parseInput()
      |> Enum.reduce(%{}, fn line, cardMap ->
        [card, numbers] = splitAndTrim(line, ":")
        winners = mapCardLineToWinningNumbers(numbers)
        [_card, number] = String.split(card)
        Map.put(cardMap, number, length(winners))
      end)

    [head | tail] = parseInput()
    iterateCardList(head, tail, length(tail) + 1, cardScoreLookup)
  end

  # slow AF, memoisation would help but I can wait the 10 secs this took to run
  defp iterateCardList(head, tail, score, lookupMap) do
    [card, _numbers] = splitAndTrim(head, ":")
    [_card, number] = String.split(card)
    cardsWon = Map.get(lookupMap, number)

    if cardsWon == 0 do
      case tail do
        [] ->
          score

        _ ->
          [new_head | tail] = tail
          iterateCardList(new_head, tail, score, lookupMap)
      end
    else
      ["Card", index_str] = splitAndTrim(card, " ")
      index = Integer.parse(index_str) |> elem(0)

      new_tail =
        List.foldl(Enum.to_list((index + 1)..(index + cardsWon)), tail, fn i, tail_acc ->
          # add the card number back into the list in the same format as the already parsed input
          ["Card " <> Integer.to_string(i) <> ": " | tail_acc]
        end)

      [new_head | tail] = new_tail
      iterateCardList(new_head, tail, score + cardsWon, lookupMap)
    end
  end

  defp mapCardLineToWinningNumbers(numbers) do
    [winning_numbers, drawn_numbers] =
      splitAndTrim(numbers, "|")
      |> Enum.map(fn nums -> splitAndTrim(nums, " ") end)

    Enum.filter(drawn_numbers, fn drawn_number ->
      Enum.member?(winning_numbers, drawn_number)
    end)
  end

  defp splitAndTrim(text, sep) do
    String.split(text, sep, trim: true)
    |> Enum.map(fn part -> String.trim(part) end)
  end

  defp parseInput() do
    File.read!("./lib/input.txt")
    |> String.split("\n", trim: true)
  end
end
