defmodule Day10 do
  def solve do
    instructions = File.read!("./lib/input.txt")
      |> String.split("\n")

    register_vals = List.foldl(instructions, [1], fn instruction, acc ->
      split_instruction = String.split(instruction, " ")
      case split_instruction do
        ["noop"] -> [get_head_or_init(acc) | acc]
        ["addx", amount] -> curr_register = get_head_or_init(acc)
          amount = Integer.parse(amount) |> elem(0)
          [amount + curr_register, curr_register] ++ acc
      end
    end)

    #strip off very last instruction
    register_vals = Enum.reverse(tl(register_vals))

    vals_to_check = gen_list(length(register_vals), 20, [])

    #this is an unhappy elixir way ...
    part1 = List.foldl(vals_to_check, [], fn index, acc ->
      [Enum.at(register_vals, index-1) * index | acc]
    end)
    |> Enum.sum()

    IO.inspect(part1)

    #iterate back through the whole list
    Enum.chunk_every(register_vals, 40)
      |> Enum.map(fn chunk ->
        List.foldl(chunk, "", fn register, line ->
          current_line_size = String.length(line) #proxy for index ... obvs not performant
          sprite = [register-1, register, register+1]
          if (Enum.member?(sprite, current_line_size)) do
            line <> "#"
          else
            line <> "."
          end
        end)
      end)
  end

  def get_head_or_init(register_vals) do
    case register_vals do
      [] -> 1
      [head | _tail] -> head
    end
  end

  def gen_list(max_length, current_index, acc) do
    if (current_index <= max_length) do
      gen_list(max_length, current_index + 40, [current_index | acc])
    else
      acc
    end
  end
end
