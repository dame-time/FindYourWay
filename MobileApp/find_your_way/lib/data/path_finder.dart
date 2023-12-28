import 'package:collection/collection.dart';
import 'dart:math';

class PathFinder {
  List<List<String>> mapMatrix;
  Point<int> start;
  Point<int> goal;

  PathFinder(this.mapMatrix, this.start, this.goal);

  List<Point<int>> findPath() {
    Set<Point<int>> closedSet = {};

    PriorityQueue<Node> openSet = PriorityQueue<Node>(
      (a, b) => a.fScore.compareTo(b.fScore),
    );
    openSet.add(Node(start, 0.0));

    Map<Point<int>, Point<int>> cameFrom = {};

    Map<Point<int>, double> gScore = {start: 0.0};

    Map<Point<int>, double> fScore = {
      start: _heuristicCostEstimate(start, goal)
    };

    while (openSet.isNotEmpty) {
      Node current = openSet.removeFirst();
      if (current.position == goal) {
        return _reconstructPath(cameFrom, current.position);
      }

      closedSet.add(current.position);

      for (var neighbor in _getNeighbors(current.position)) {
        if (closedSet.contains(neighbor)) continue;

        double tentativeGScore = gScore[current.position]! +
            _distBetween(current.position, neighbor);

        if (!openSet.toSet().any((node) => node.position == neighbor) ||
            tentativeGScore < gScore[neighbor]!) {
          cameFrom[neighbor] = current.position;
          gScore[neighbor] = tentativeGScore;
          fScore[neighbor] =
              tentativeGScore + _heuristicCostEstimate(neighbor, goal);
          if (!openSet.toSet().any((node) => node.position == neighbor)) {
            openSet.add(Node(neighbor, fScore[neighbor]!));
          }
        }
      }
    }

    return [];
  }

  double _heuristicCostEstimate(Point<int> start, Point<int> end) {
    // Using Euclidean distance as a heuristic
    return sqrt(pow(start.x.toDouble() - end.x.toDouble(), 2).toDouble() +
        pow(start.y.toDouble() - end.y.toDouble(), 2).toDouble());
  }

  double _distBetween(Point<int> start, Point<int> end) {
    return 1.0;
  }

  Iterable<Point<int>> _getNeighbors(Point<int> position) {
    List<Point<int>> neighbors = [];
    List<Point<int>> possibleMoves = [
      Point(position.x + 1, position.y),
      Point(position.x - 1, position.y),
      Point(position.x, position.y + 1),
      Point(position.x, position.y - 1),
    ];

    for (var move in possibleMoves) {
      if (move.x >= 0 &&
          move.x < mapMatrix.length &&
          move.y >= 0 &&
          move.y < mapMatrix[0].length &&
          mapMatrix[move.x][move.y] != '0') {
        neighbors.add(move);
      }
    }
    return neighbors;
  }

  List<Point<int>> _reconstructPath(
      Map<Point<int>, Point<int>> cameFrom, Point<int> current) {
    List<Point<int>> totalPath = [current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      totalPath.insert(0, current);
    }
    return totalPath;
  }
}

class Node {
  final Point<int> position;
  final double fScore;

  Node(this.position, this.fScore);
}
