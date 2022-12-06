defmodule Crates do

  def solve do
    lines = File.read!("./lib/input.txt")
      |> String.split("\n")

    # build map like {1 => [a,b,c], 2 => [x]}
    initial_state = lines |> Enum.take_while(fn line -> String.contains?(line, "[") end)
      |> Enum.map(fn line ->
        Enum.chunk_every(line |> String.graphemes(), 4)
        |> Enum.map(fn lst -> hd(tl(lst)) end) #i.e. get 2nd in e.g. ["[", "Z", "]", " "]
        |> List.foldr([], fn crate, acc -> [crate | acc] end)
      end)
      |> List.foldl(%{}, fn row, crates_map ->
        updated_map = List.foldl(Enum.to_list(1..length(row)), crates_map, fn index, crates_map ->
          new_val = Enum.at(row, index-1)
          case Map.has_key?(crates_map, index) do
            true -> Map.update!(crates_map, index, fn existing_items ->
              case new_val do
                " " -> existing_items
                _ -> existing_items ++ [new_val]
              end
            end)
            false -> case new_val do
              " " -> Map.put(crates_map, index, [])
              _ -> Map.put(crates_map, index, [new_val])
            end
          end
        end)
        updated_map
      end)


    moves = lines
      |> Enum.filter(fn line -> String.contains?(line, "from") end)
      |> Enum.map(fn line -> String.split(line, " ") end)

    moved_crates = List.foldl(moves, initial_state, fn line, crates ->
        ["move", num_crates, "from", start_pile, "to", end_pile] = line
        start_pile = String.to_integer(start_pile)
        end_pile = String.to_integer(end_pile)
        num_crates = String.to_integer(num_crates)
        starting_crates = Map.get(crates, start_pile)
        crates_to_move = starting_crates |> Enum.slice(0, num_crates)

        updated_state = List.foldr(crates_to_move, crates, fn crate, acc ->
          acc = Map.update!(acc, end_pile, fn existing_val ->
            [crate | existing_val]
          end)
          Map.update!(acc, start_pile, fn existing_val ->
            case existing_val do
              [_val] -> []
              _ -> tl(existing_val)
            end
          end)
        end)

        updated_state
    end)

  Enum.map(moved_crates, fn {_k,v} ->
    case v do
      [] -> ""
      _ -> hd(v)
    end
  end)
    |> Enum.join("")
  end
end
