defmodule Directory6 do
  defmodule Directory do
    defstruct parent: "", name: "", child_dirs: [], files: []
  end

  def solve do
    #have a directory as a map of subdirectories and a list of files

    #pointer to parent dir
    #list of child dirs
    #list of files

    lines = File.read!("./lib/input.txt")
      |> String.split("\n")

    List.foldl(lines, %Directory{}, fn line, acc ->
      if String.contains?(line, "cd")
    end)
  end

  defp populate_dir(line, dir) do
    if (String.contains?(line, "ls"))
  end

  defp find_dir(directory, name) do
    case directory.name do
      name -> directory
      _ -> case directory.child_dirs do
        [] -> %Directory {}

      end
    end
  end

end
