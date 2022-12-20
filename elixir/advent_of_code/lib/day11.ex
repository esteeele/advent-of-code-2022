defmodule Day11 do
  def solve do
    monkeys =
      File.read!("./lib/input.txt")
      |> String.split("\n")
      |> Enum.chunk_every(7)
      |> Enum.map(fn monkey_input -> parse_input(monkey_input) end)

    # use modular arithmetic (get product of all divisors then mod by it)
    modulo_product =
      Enum.reduce(monkeys, 1, fn monkey, acc -> acc * Map.get(monkey, :divisor) end)

    monkeys_end_state =
      List.foldl(Enum.to_list(1..10000), monkeys, fn _round, monkeys_acc ->
        #for each round, iterate through each monkey and update state with what happens
        List.foldl(Enum.to_list(0..(length(monkeys) - 1)), monkeys_acc, fn index,
                                                                           monkeys_list_acc ->
          monkey_input = Enum.at(monkeys_list_acc, index)

          List.foldl(Map.get(monkey_input, :starting_items, []), monkeys_list_acc, fn item,
                                                                                      acc_monks ->
            monkey = Enum.at(acc_monks, index)

            operand =
              case Map.get(monkey, :operand) do
                "old" -> item
                _ -> Map.get(monkey, :operand) |> String.to_integer()
              end

            operation = map_operation_to_func(Map.get(monkey, :operator))

            result = operation.(item, operand)

            # result = div(result, 3) part 1
            result = Integer.mod(result, modulo_product)

            dest_monkey_index =
              if Integer.mod(result, Map.get(monkey, :divisor)) == 0 do
                Map.get(monkey, :monkey_dest_true)
              else
                Map.get(monkey, :monkey_dest_false)
              end

            dest_monkey = Enum.at(acc_monks, dest_monkey_index)

            dest_monkey =
              Map.update(dest_monkey, :starting_items, [result], fn existing_val ->
                existing_val ++ [result]
              end)

            monkey =
              Map.update(monkey, :starting_items, [], fn existing_val ->
                tl(existing_val)
              end)

            monkey = Map.update(monkey, :inspections, 1, fn existing_val -> existing_val + 1 end)

            # reconstruct list
            rebuild_monkeys(acc_monks, index, monkey, dest_monkey_index, dest_monkey)
          end)
        end)
      end)

    IO.inspect(monkeys_end_state, charlists: :as_list)

    sorted_monkeys =
      Enum.sort(monkeys_end_state, fn monkey_1, monkey_2 ->
        Map.get(monkey_1, :inspections) > Map.get(monkey_2, :inspections)
      end)
      |> Enum.take(2)
      |> Enum.map(fn monkey -> Map.get(monkey, :inspections) end)
      |> Enum.reduce(fn x, acc -> x * acc end)

    IO.inspect(sorted_monkeys)
  end

  def parse_input(monkey_input) do
    monkey_input =
      Enum.map(monkey_input, fn line -> String.trim(line) end)
      |> Enum.filter(fn line -> line != "" end)

    # pattern matching don't fail me now
    monkey_number =
      Enum.at(monkey_input, 0)
      |> String.split()
      |> Enum.at(1)
      |> String.replace(":", "")
      |> String.to_integer()

    starting_items =
      Enum.at(monkey_input, 1)
      |> String.replace("Starting items: ", "")
      |> String.split(",")
      |> Enum.map(fn num -> String.trim(num) end)
      |> Enum.map(fn num -> String.to_integer(num) end)

    operation =
      Enum.at(monkey_input, 2)
      |> String.split(" ")
      |> tl()

    ["new", "=", "old", operator, operand] = operation

    divisor = get_integer_at_end_of_line(Enum.at(monkey_input, 3))

    monkey_dest_true = get_integer_at_end_of_line(Enum.at(monkey_input, 4))

    monkey_dest_false = get_integer_at_end_of_line(Enum.at(monkey_input, 5))

    %{
      :monkey_id => monkey_number,
      :starting_items => starting_items,
      :operator => operator,
      :operand => operand,
      :divisor => divisor,
      :monkey_dest_true => monkey_dest_true,
      :monkey_dest_false => monkey_dest_false,
      :inspections => 0
    }
  end

  def map_operation_to_func(raw_operation) do
    case raw_operation do
      "+" -> fn arg1, arg2 -> arg1 + arg2 end
      "*" -> fn arg1, arg2 -> arg1 * arg2 end
      "_" -> :error
    end
  end

  def rebuild_monkeys(
        acc_monks,
        source_monkey_index,
        source_monkey,
        dest_monkey_index,
        dest_monkey
      ) do
    List.foldr(Enum.to_list(0..(length(acc_monks) - 1)), [], fn monk_index, rebuilt_list ->
      cond do
        monk_index == dest_monkey_index -> [dest_monkey | rebuilt_list]
        monk_index == source_monkey_index -> [source_monkey | rebuilt_list]
        true -> [Enum.at(acc_monks, monk_index) | rebuilt_list]
      end
    end)
  end

  def add(arg1, arg2) do
    arg1 + arg2
  end

  def multiply(arg1, arg2) do
    arg1 * arg2
  end

  def get_integer_at_end_of_line(line) do
    line
    |> String.split(" ")
    |> Enum.reverse()
    |> hd()
    |> String.to_integer()
  end
end
