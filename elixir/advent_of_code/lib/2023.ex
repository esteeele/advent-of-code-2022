defmodule Advent2023 do
  alias Advent2023.SeedMaps

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
    inputLines = parseInput()

    cardScoreLookup =
      inputLines
      |> Enum.reduce(%{}, fn line, cardMap ->
        [card, numbers] = splitAndTrim(line, ":")
        winners = mapCardLineToWinningNumbers(numbers)
        # i'm not sure why this did what I expected it to ...
        [_card, number] = String.split(card)
        Map.put(cardMap, number, length(winners))
      end)

    [head | tail] = inputLines
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

  defp convert_to_int(text) do
    Integer.parse(text) |> elem(0)
  end

  # day 5
  defmodule SeedMaps do
    defstruct source: "",
              destination: "",
              sourceStart: 0,
              destStart: 0,
              offset: 0,
              transformation: 0
  end

  defmodule Range do
    defstruct range_start: nil, range_end: nil
  end

  def day5P1 do
    value = %SeedMaps{}
    inputLines = parseInput()
    [seeds | tail] = inputLines
    IO.inspect(seeds)

    # process seeds
    all_mappings =
      Enum.reduce(tail, %{}, fn line, map ->
        cond do
          String.contains?(line, "-to-") ->
            [source, "to", destination] =
              String.split(String.replace(line, " map:", ""), "-", trim: true)

            map = Map.put(map, "current_source", source)
            Map.put(map, "current_dest", destination)

          Regex.match?(~r/\d+/, line) ->
            [dest_start, source_start, range_size] =
              String.split(line, " ", trim: true)
              |> Enum.map(fn elem -> Integer.parse(elem) |> elem(0) end)

            # add to a list for the source map
            mapping = %SeedMaps{
              source: Map.get(map, "current_source"),
              destination: Map.get(map, "current_dest"),
              sourceStart: source_start,
              destStart: dest_start,
              offset: range_size,
              transformation: dest_start - source_start
            }

            Map.update(map, Map.get(map, "current_source"), [mapping], fn existing_list ->
              [mapping | existing_list]
            end)

          true ->
            map
        end
      end)
    IO.inspect(all_mappings)

    IO.inspect(tl(splitAndTrim(seeds, ":")))

    least_location =
      tl(splitAndTrim(seeds, ":"))
      |> hd()
      |> splitAndTrim(" ")
      |> Enum.map(fn value -> convert_to_int(value) end)
      |> Enum.map(fn seedValue ->
        down_the_seed_hole(%Range{range_start: seedValue, range_end: seedValue}, all_mappings, "seed")
      end)
      |> Enum.min()

    # reprocess the mappings map working backwards finding for each mapping zone finding
    # the least offset

    seeds =
      tl(splitAndTrim(seeds, ":"))
      |> hd()
      |> splitAndTrim(" ")
      |> Enum.map(fn value -> convert_to_int(value) end)
      |> Enum.chunk_every(2, 2)
      |> Enum.reduce(%{}, fn [start, range], lookup_acc ->
        lookup_acc
      end)

    """
    Work from back to front building up a ds that points a range to the min
    value - if something is outside this range it is self
    """

    # seeds |> Enum.min_by(fn {_k, v} -> v end)
    # IO.inspect(seeds)
    # build maps
    least_location
  end

  defp down_the_seed_hole(range, mappings, source) do
    mapping_list = Map.get(mappings, source)
    range_start = range.range_start
    range_end = range.range_end
    IO.inspect(length(mapping_list))

    filtered_map =
      Enum.filter(mapping_list, fn seed_map ->
        # here replace this with range overlap vs individual
        # so like split out the range based on what overlaps
        # need to build a map of which ranges point to which offsets
        # for a range, find the number of ways it could be mapped then find the min of these
        # and also store the values in case the same range gets hit a second time?

        #completely contained in another range, what happens if not?
        range_start >= seed_map.sourceStart and range_end  <= seed_map.sourceStart + seed_map.offset
      end)

    next_dest = hd(mapping_list).destination
    possible_transformations = case filtered_map do
      [] -> [0]
      _ -> Enum.map(filtered_map, fn map -> map.transformation end)
    end
    Enum.map(possible_transformations, fn transformation ->
      next_input = range_start + transformation
      if next_dest == "location" do
        next_input
      else
        down_the_seed_hole(%Range{range_start: next_input, range_end: next_input}, mappings, next_dest)
      end
    end)
    |> Enum.min()
  end

  def day6P1 do
    times_and_distances = parseInput()
      |> Enum.map(fn line -> splitAndTrim(line, ":") |> tl() end)
      |> Enum.map(fn numbers ->
        splitAndTrim(hd(numbers), " ")
        |> Enum.map(fn number_str -> convert_to_int(number_str) end)
      end)
      |> Enum.zip()

    [time, distance] = parseInput()
      |> Enum.map(fn line -> splitAndTrim(line, ":") |> tl() end)
      |> Enum.map(fn numbers ->
        convert_to_int(String.replace(hd(numbers), " ", ""))
      end)

    #part 2
    times_and_distances = [{time, distance}]

    Enum.map(times_and_distances, fn {race_time, distance} ->
      # y = race_time * x - x^2 and y = distance
      quadratic = abs(-race_time + (:math.sqrt(race_time * race_time - 4 * -1 * -distance))) / 2
      range_start = ceil(quadratic + 0.01) # ensures we round to the nearest int + 1 (lack of Elixir knowledge...)
      range_end = race_time - floor(quadratic)
      range_end - range_start
    end)
    |> Enum.reduce(1, fn possible_ways, acc -> acc * possible_ways end)
  end
end
