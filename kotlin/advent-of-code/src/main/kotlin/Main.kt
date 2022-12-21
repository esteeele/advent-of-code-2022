import java.io.File

fun main(args: Array<String>) {
    println("Hello World!")

    // Try adding program arguments via Run/Debug configuration.
    // Learn more about running applications: https://www.jetbrains.com/help/idea/running-applications.html.

    val lines = File("/Users/ed/Documents/code/advent-of-code-2022/kotlin/advent-of-code/src/main/resources/input.txt").readLines()
    val aoc = solve(lines)
    println(aoc)

    println("Program arguments: ${args.joinToString()}")
}