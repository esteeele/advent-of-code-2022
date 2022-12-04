defmodule Day4Pairs do
  def solve(part) do
    both_overlap = fn [a,b,c,d] -> (a <= c and b >= d) or (c <= a and d >= b) end
    any_overlap = fn [a,b,c,d] -> max(a,c) <= min(b,d) end

    File.read!("./lib/input.txt")
      |> String.split("\n")
      |> Enum.map(fn line -> List.foldl(String.split(line, ","), [], fn pair, acc ->
        pair = String.split(pair, "-") |> Enum.map(fn num -> String.to_integer(num) end)
        acc ++ pair
      end)
      end)
      |> Enum.filter(fn line ->
        case part do
          :one -> both_overlap.(line)
          :two -> any_overlap.(line)
          _ -> false
        end
      end)
      |> Enum.count()
  end
end
