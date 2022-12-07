defmodule Packets5 do
  def solve(msg_length) do
    packet = File.read!("./lib/input.txt")

    first_index = packet
    |> String.graphemes()
    |> Enum.chunk_every(msg_length, 1)
    |> Enum.take_while(fn chunk -> length(Enum.uniq(chunk)) != msg_length end)
    |> Enum.count()

    #offset by n as we're returning at the start of the marker
    IO.inspect(first_index + msg_length)
  end
end
