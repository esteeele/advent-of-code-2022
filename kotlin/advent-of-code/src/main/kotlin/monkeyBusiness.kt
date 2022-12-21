public fun solve(lines: List<String>) {
    val rootMaths = extractRootMonkey(lines)

    //map associates the monkeys we know and what numbers they have
    val knownMonkeys = lines.map { line -> line.split(" ") }
        .filter { line -> line.size == 2 }
        .associate { line -> line[0].replace(":", "") to line[1].toLong() }

    val monkeys: List<MonkeyMaths> = lines.map { line -> line.split(" ") }
        .filter { line -> line.size > 2 }
        .map { line -> parseMonkey(line) }

    val finishedMonkeys: Map<String, Long> = fillInValues(knownMonkeys, monkeys, rootMaths)
    val rootValuePart1: Long = findValueForEquation(finishedMonkeys, rootMaths)
    println(rootValuePart1)

    //part 2
    val part2Map = knownMonkeys.toMutableMap()
    part2Map.remove("humn")

    val partiallyCompleteMonkeys: MutableMap<String, Long> = fillInValues(part2Map, monkeys, rootMaths)
        .toMutableMap()
    /**
     * e.g.
     * root = pppw = sjmn (we know sjmm is 150) so pppw must be 150 as well
     * pppw = cczh / lfqf (we know lfgf is 4 so it becomes 150 = cczh / 4 so cczh = 600
     * cczh = sllz + lgvd (we know cczh is 600, sllz is 4 so lgvd is 596) ... and so on
     */
    //roots kinda a special case so handle outside of main iteration
    val op1 = rootMaths.operandMonkey1
    val op2 = rootMaths.operandMonkey2

    val nextMonkey = if (partiallyCompleteMonkeys.containsKey(op1)) {
        partiallyCompleteMonkeys[op2] = partiallyCompleteMonkeys.getValue(op1)
        monkeys.find { monkey -> monkey.resultMonkey == op2 }!!
    } else if (partiallyCompleteMonkeys[op2] != null) {
        partiallyCompleteMonkeys[op1] = partiallyCompleteMonkeys.getValue(op2)
        monkeys.find { monkey -> monkey.resultMonkey == op1 }!!
    } else {
        throw RuntimeException("Unsolvable, neither monkey is known!")
    }
    val completedMonkeys = monkeyChainToHuman(nextMonkey, partiallyCompleteMonkeys, monkeys)
    println("Right answer maybe")
    println(completedMonkeys.getValue("humn"))
}

//rejig equation as we know result and one operand, but not the other
private fun monkeyChainToHuman(
    monkeyToFigureOut: MonkeyMaths, knownMonkeys: Map<String, Long>,
    monkeys: List<MonkeyMaths>
): Map<String, Long> {
    val selfValue = knownMonkeys.getValue(monkeyToFigureOut.resultMonkey)

    val op1 = monkeyToFigureOut.operandMonkey1
    val op2 = monkeyToFigureOut.operandMonkey2

    val nextMonkey: MonkeyWithResult = if (knownMonkeys.containsKey(op1)) {
        val knownOperand = knownMonkeys.getValue(op1)
        //for divs and subtracts order is important so make sure we get right
        val operand = when (monkeyToFigureOut.operator) {
            Operator.DIVIDE -> knownOperand.div(selfValue)
            Operator.SUBTRACT -> knownOperand - selfValue
            else -> monkeyToFigureOut.operator.inverseFunction(selfValue, knownOperand)
        }
        MonkeyWithResult(op2, operand)
    } else if (knownMonkeys.containsKey(op2)) {
        val knownOperand = knownMonkeys.getValue(op2)
        val operand = monkeyToFigureOut.operator.inverseFunction(selfValue, knownOperand)
        MonkeyWithResult(op1, operand)
    } else {
        throw RuntimeException("Unsolvable, neither monkey is known!")
    }

    val updatedMonkeys = knownMonkeys.toMutableMap()
    updatedMonkeys[nextMonkey.monkeyName] = nextMonkey.monkeyValue
    if (nextMonkey.monkeyName == "humn") {
        return updatedMonkeys
    }
    val nextMonkeyInList = monkeys.find { monkey -> monkey.resultMonkey == nextMonkey.monkeyName }!!

    return monkeyChainToHuman(nextMonkeyInList, updatedMonkeys, monkeys)
}

private fun extractRootMonkey(lines: List<String>): MonkeyMaths {
    val rootMaths = lines.filter { line -> line.contains("root") }
        .map { line -> parseMonkey(line.split(" ")) }
        .first();
    return rootMaths
}

private fun fillInValues(
    knownMonkeys: Map<String, Long>,
    unknownMonkeys: List<MonkeyMaths>,
    root: MonkeyMaths
): Map<String, Long> {
    if (knownMonkeys.containsKey(root.operandMonkey1) and knownMonkeys.containsKey(root.operandMonkey2)) {
        return knownMonkeys
    } else {
        val newlyDiscoveredVals: MutableMap<String, Long> = unknownMonkeys
            .filter { monkey ->
                knownMonkeys.containsKey(monkey.operandMonkey1)
                        && knownMonkeys.containsKey(monkey.operandMonkey2)
            }
            .map { monkeyMaths ->
                val result = findValueForEquation(knownMonkeys, monkeyMaths)
                MonkeyWithResult(monkeyMaths.resultMonkey, result)
            }
            .associate { monkeyResult -> monkeyResult.monkeyName to monkeyResult.monkeyValue }
            .toMutableMap()
        if (newlyDiscoveredVals.isEmpty()) {
            //can't solve anymore (part 2 thing)
            return knownMonkeys
        }

        newlyDiscoveredVals.putAll(knownMonkeys)

        return fillInValues(
            newlyDiscoveredVals,
            unknownMonkeys.filter { monkey -> !newlyDiscoveredVals.containsKey(monkey.resultMonkey) },
            root
        )
    }
}

private fun findValueForEquation(
    knownMonkeys: Map<String, Long>,
    monkeyMaths: MonkeyMaths
): Long {
    val operand1Value = knownMonkeys.getValue(monkeyMaths.operandMonkey1)
    val operand2Value = knownMonkeys.getValue(monkeyMaths.operandMonkey2)
    return monkeyMaths.operator.function(operand1Value, operand2Value)
}

private fun parseMonkey(splitLine: List<String>): MonkeyMaths {
    val opRaw = splitLine[2]
    val operator: Operator = Operator.values().first { op -> op.rawVal == opRaw }
    return MonkeyMaths(splitLine[0].replace(":", ""), splitLine[1], splitLine[3], operator)
}

enum class Operator(val rawVal: String, val function: (Long, Long) -> Long, val inverseFunction: (Long, Long) -> Long) {
    ADD("+", Long::plus, Long::minus),
    SUBTRACT("-", Long::minus, Long::plus),
    MULTIPLY("*", Long::times, Long::div),
    DIVIDE("/", Long::div, Long::times)
}

class MonkeyMaths(
    val resultMonkey: String, val operandMonkey1: String,
    val operandMonkey2: String, val operator: Operator
)

class MonkeyWithResult(val monkeyName: String, val monkeyValue: Long)