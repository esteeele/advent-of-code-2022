class File(val name: String, val size: Long)

val free_space = 30000000

class Node(
    val name: String,
    var childNodes: MutableList<Node>,
    var files: MutableList<File>,
    val parent: Node?,
    var totalFileSize: Long = 0,
    var fileSizeIncludingChild: Long = 0
)

public fun parseDirector(lines: List<String>) : Long {
    var tree = Node("home", mutableListOf(), mutableListOf(), null)

    for (line in lines.subList(1, lines.size)) {
        if (line.contains("$")) {
            if (line.contains("ls")) {
                //no-op
            } else if (line.contains("cd")) {
                val directory = line.replace("$ cd ", "")
                tree = if (directory == "..") {
                    tree.parent ?: tree //I've reached the top and had to stop
                } else {
                    findNodeOrMakeNew(tree, directory)
                }
            }
        } else {
            if (line.contains("dir")) {
                val name = line.replace("dir ", "")
                if (!tree.childNodes.any { it.name == name }) {
                    tree.childNodes.add(Node(name, mutableListOf(), mutableListOf(), tree))
                }
            } else {
                val fileLine = line.split(" ")
                val fileSize = fileLine[0].toLong()
                tree.files.add(
                    File(fileLine[1], fileSize)
                )
                tree.totalFileSize += fileSize
            }
        }
    }

    while (tree.parent != null) {
        tree = tree.parent!!
    }

    fillInTotalSpaceUsedForEachDir(tree)

    //part1
    val size = countQualifyingSizes(tree)

    //part 2
    val totalSpaceUsed = tree.fileSizeIncludingChild
    val unusedSpace = 70000000 - totalSpaceUsed
    val spaceToFree = 30000000 - unusedSpace

    val minNode = findSmallestDirectory(tree,
        Node("FOO", mutableListOf(), mutableListOf(), tree, Long.MAX_VALUE, Long.MAX_VALUE), spaceToFree)
    println(minNode.fileSizeIncludingChild)

    return minNode.fileSizeIncludingChild
}

private fun findNodeOrMakeNew(tree: Node, directory: String): Node {
    val childNode: Node? = tree.childNodes.find { node -> node.name == directory }
    if (childNode != null) {
        return childNode
    } else if (tree.parent != null && tree.parent.name == directory) {
        return tree.parent
    }
    val newNode = Node(directory, mutableListOf(), mutableListOf(), tree)
    tree.childNodes.add(newNode)
    return newNode
}

fun fillInTotalSpaceUsedForEachDir(node: Node) {
    val fileSizeOnLevel = node.files.sumOf { file -> file.size }

    node.fileSizeIncludingChild += fileSizeOnLevel
    var parent = node.parent
    while (parent != null) {
        parent.fileSizeIncludingChild += node.fileSizeIncludingChild
        parent = parent.parent
    }
    for (childNode in node.childNodes) {
        fillInTotalSpaceUsedForEachDir(childNode)
    }
}

fun countQualifyingSizes(node: Node) : Long {
    var totalSize: Long = 0

    if (node.fileSizeIncludingChild <= 100_000) {
        totalSize += node.fileSizeIncludingChild
    }

    for (childNode in node.childNodes) {
        totalSize += countQualifyingSizes(childNode)
    }

    return totalSize
}

fun findSmallestDirectory(node: Node, localMin: Node, spaceToFree: Long) : Node {
    var minNode = localMin
    if (node.fileSizeIncludingChild >= spaceToFree) {
        if (minNode.fileSizeIncludingChild > node.fileSizeIncludingChild) {
            minNode = node
        }
    }

    for (childNode in node.childNodes) {
        minNode = findSmallestDirectory(childNode, minNode, spaceToFree)
    }
    return minNode
}

