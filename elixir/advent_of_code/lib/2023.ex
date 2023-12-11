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
        down_the_seed_hole(
          %Range{range_start: seedValue, range_end: seedValue},
          all_mappings,
          "seed"
        )
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

        # completely contained in another range, what happens if not?
        range_start >= seed_map.sourceStart and
          range_end <= seed_map.sourceStart + seed_map.offset
      end)

    next_dest = hd(mapping_list).destination

    possible_transformations =
      case filtered_map do
        [] -> [0]
        _ -> Enum.map(filtered_map, fn map -> map.transformation end)
      end

    Enum.map(possible_transformations, fn transformation ->
      next_input = range_start + transformation

      if next_dest == "location" do
        next_input
      else
        down_the_seed_hole(
          %Range{range_start: next_input, range_end: next_input},
          mappings,
          next_dest
        )
      end
    end)
    |> Enum.min()
  end

  def day6P1 do
    numbers =
      parseInput()
      |> Enum.map(fn line -> splitAndTrim(line, ":") |> tl() end)

    times_and_distances =
      numbers
      |> Enum.map(fn numbers ->
        splitAndTrim(hd(numbers), " ")
        |> Enum.map(fn number_str -> convert_to_int(number_str) end)
      end)
      |> Enum.zip()

    [time, distance] =
      numbers
      |> Enum.map(fn numbers ->
        convert_to_int(String.replace(hd(numbers), " ", ""))
      end)

    # part 2
    times_and_distances = [{time, distance}]

    Enum.map(times_and_distances, fn {race_time, distance} ->
      # distance = race_time * held_time - held_time^2
      # solve for held_time when distance is the max current distance then find range
      quadratic = abs(-race_time + :math.sqrt(race_time * race_time - 4 * -1 * -distance)) / 2
      range_start = ceil(quadratic)
      range_end = race_time - floor(quadratic)
      ceil(range_end) - floor(range_start) - 1
    end)
    |> Enum.reduce(1, fn possible_ways, acc -> acc * possible_ways end)
  end

  defp find_max_value_in_map(map) do
    sorted_freq_map =
      map
      |> Map.to_list()
      |> Enum.sort(fn {_key, value}, {key_2, value_2} -> value > value_2 end)

    [{max_key, max_value} | tail] = sorted_freq_map

    case max_key do
      "J" ->
        case tail do
          [] ->
            {"J", map}

          _ ->
            {second_key, second_value} = hd(tail)
            map = Map.put(map, second_key, second_value + Map.get(map, "J", 0))
            map = Map.delete(map, "J")
            {second_key, map}
        end

      _ ->
        map = Map.put(map, max_key, max_value + Map.get(map, "J", 0))
        map = Map.delete(map, "J")
        {max_key, map}
    end
  end

  def map_card_to_number(card, lookup_map) do
    if Map.has_key?(lookup_map, card) do
      Map.get(lookup_map, card)
    else
      String.to_integer(card)
    end
  end

  def iterate_through_strings_until_difference(cardset_a, cardset_b, lookup_map) do
    case cardset_a do
      "" ->
        :card_a

      _ ->
        card_a_value = map_card_to_number(String.first(cardset_a), lookup_map)
        card_b_value = map_card_to_number(String.first(cardset_b), lookup_map)

        case card_a_value - card_b_value do
          0 ->
            iterate_through_strings_until_difference(
              String.slice(cardset_a, 1, 5),
              String.slice(cardset_b, 1, 5),
              lookup_map
            )

          neg when neg < 0 ->
            :card_b

          pos when pos > 0 ->
            :card_a
        end
    end
  end

  def day7P1 do
    lookup_map = %{
      "A" => 14,
      "K" => 13,
      "Q" => 12,
      "J" => 1,
      "T" => 10
    }

    # for part 2 probably best approach is find max char without J then assume J is that char
    # if J is max char then find the strongest other char in freq map

    numbers =
      parseInput()
      |> Enum.map(fn line -> splitAndTrim(line, " ") end)
      |> Enum.map(fn [hand, bid] ->
        freq_map = Enum.frequencies(String.graphemes(hand))
        {freq_map, convert_to_int(bid), hand}
      end)
      |> Enum.sort(fn {freq_map_a, bid_a, cards_a}, {freq_map_b, bid_b, cards_b} ->
        {max_key_a, updated_map_a} = find_max_value_in_map(freq_map_a)
        {max_key_b, updated_map_b} = find_max_value_in_map(freq_map_b)

        max_matching_cards_a = Map.get(updated_map_a, max_key_a)
        max_matching_cards_b = Map.get(updated_map_b, max_key_b)

        # return true if the first argument preceeds the latter

        stronger_card =
          case max_matching_cards_a - max_matching_cards_b do
            0 ->
              # horrible check for a full house
              stronger_card =
                case {max_matching_cards_a, map_size(updated_map_a), map_size(updated_map_b)} do
                  {3, 2, b} when b != 2 ->
                    :card_a

                  {3, a, 2} when a != 2 ->
                    :card_b

                  # horrible check for 2 pair
                  {2, 3, b} when b != 3 ->
                    :card_a

                  {2, a, 3} when a != 3 ->
                    :card_b

                  _ ->
                    iterate_through_strings_until_difference(
                      cards_a,
                      cards_b,
                      lookup_map
                    )
                end

              case stronger_card do
                :card_a -> true
                :card_b -> false
              end

            _ ->
              max_matching_cards_a >= max_matching_cards_b
          end
      end)

    numbers
    |> Enum.reverse()
    |> Enum.reduce({0, 1}, fn {map, bid, hand}, {running_sum, rank} ->
      # {%{"A" => 1, "J" => 1, "Q" => 3}, 483, "QQQJA"}
      {running_sum + rank * bid, rank + 1}
    end)
    |> elem(0)
  end

  def day8 do
    lines = parseInput()

    nodes = tl(lines)

    lookup_map =
      Enum.reduce(nodes, %{}, fn line, lookup_map ->
        [node_name, left_right] = splitAndTrim(line, "=")
        [left, right] = splitAndTrim(left_right, ",")
        left = String.replace_prefix(left, "(", "")
        right = String.replace_suffix(right, ")", "")
        Map.put(lookup_map, node_name, [left, right])
      end)

    instructions = String.graphemes(hd(lines))
    # part1 = recurse_through_instructions("11A", instructions, lookup_map, 0, "Z")
    IO.inspect(lookup_map)

    steps_for_each_node =
      Enum.filter(lookup_map, fn {key, value} ->
        String.ends_with?(key, "A")
      end)
      |> Enum.map(fn {key, value} ->
        recurse_through_instructions(key, instructions, lookup_map, 0, "Z")
      end)

    [head | tail] = steps_for_each_node

    Enum.reduce(tail, head, fn term, acc ->
      div(abs(term * acc), gcd(acc, rem(term, acc)))
    end)

    # OK so for each steps is a cycle and we need to find when each cycle will all line up at once
  end

  defp gcd(a, 0), do: a
  defp gcd(a, b), do: gcd(b, rem(a, b))

  defp find_next_node(node, instruction, lookup_map) do
    [left, right] = Map.get(lookup_map, node)

    case instruction do
      "L" -> left
      "R" -> right
    end
  end

  # defp day8_bruteforce(current_nodes, instructions_list, steps, lookup_map) do
  #   all_match =
  #     Enum.map(current_nodes, fn node -> String.ends_with?(node, "Z") end)
  #     |> Enum.all?()

  #   if all_match do
  #     steps
  #   else
  #     instruction = hd(instructions_list)
  #     next_nodes = Enum.map(current_nodes, fn node ->
  #       find_next_node(node, instruction, lookup_map)
  #     end)
  #     day8_part2(next_nodes, tl(instructions_list) ++ [instruction], steps + 1, lookup_map)
  #   end
  # end

  defp recurse_through_instructions(node, instructions_list, lookup_map, steps, match_criteria) do
    case String.ends_with?(node, match_criteria) do
      true ->
        steps

      _ ->
        instruction = hd(instructions_list)
        next_node = find_next_node(node, instruction, lookup_map)

        recurse_through_instructions(
          next_node,
          tl(instructions_list) ++ [instruction],
          lookup_map,
          steps + 1,
          match_criteria
        )
    end
  end

  def day9 do
    # there IS a function that can compute n + 1 for all sequences (otherwise this wouldn't work at all)
    # there is definitely something related to the number of times you recurse being quadratic that would speed this up...
    # oh well brute force
    lines = parseInput()

    Enum.reduce(lines, 0, fn line, acc ->
      sequence = splitAndTrim(line, " ") |> Enum.map(fn num -> convert_to_int(num) end)
      meta_list = recursively_find_differences(sequence, [sequence])

      _part_one =
        Enum.reduce(meta_list, 0, fn sub_list, sub_acc ->
          sub_acc + hd(Enum.reverse(sub_list))
        end)

      # I guess work back up the list keeping the diff in a variable ...
      nMinusOneTerm =
        Enum.reduce(Enum.reverse(meta_list), {0, 0}, fn line, {sub_acc, prev_term} ->
          res = hd(line) - prev_term
          {sub_acc + res, res}
        end)
        |> elem(1)

      acc + nMinusOneTerm
    end)
  end

  def findDifferences(sequence) do
    Enum.chunk_every(sequence, 2, 1, :discard)
    |> Enum.map(fn [first, second] -> second - first end)
  end

  def recursively_find_differences(sequence, all_sequences) do
    differences = findDifferences(sequence)
    allZeros = Enum.all?(differences, fn diff -> diff == 0 end)

    case allZeros do
      false -> recursively_find_differences(differences, all_sequences ++ [differences])
      true -> all_sequences ++ [differences]
    end
  end
end
