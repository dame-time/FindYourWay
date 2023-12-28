import 'dart:math';

import 'package:find_your_way/data/path_finder.dart';
import 'package:flutter/material.dart';

class SurfaceMapTest extends StatefulWidget {
  const SurfaceMapTest({super.key});

  @override
  State<SurfaceMapTest> createState() => _SurfaceMapState();
}

class _SurfaceMapState extends State<SurfaceMapTest> {
  late List<List<String>> mapMatrix;
  int? lastClickedRow;
  int? lastClickedCol;

  @override
  void initState() {
    super.initState();
    mapMatrix = _parseInput('''
X111111100011111
1111111100111111
1111111100011X11
1111111121111111
X111111100020011
1111111103333011
1111111103333011
1111111103333011
''');
  }

  List<Point<int>> path = [];

  void calculateAndDisplayPath() {
    int startX = 0, startY = 0;
    for (int i = 0; i < mapMatrix.length; i++) {
      for (int j = 0; j < mapMatrix[i].length; j++) {
        if (mapMatrix[i][j] == 'U') {
          startX = i;
          startY = j;
          break;
        }
      }
    }

    if (lastClickedRow != null && lastClickedCol != null) {
      Point<int> start = Point(startX, startY);
      Point<int> goal = Point(lastClickedRow!, lastClickedCol!);
      PathFinder pathFinder = PathFinder(mapMatrix, start, goal);

      setState(() {
        path = pathFinder.findPath();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Size screenSize = MediaQuery.of(context).size;
    double cellSize = screenSize.width / mapMatrix[0].length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Your Way!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.house),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: mapMatrix[0].length,
                  ),
                  itemCount: mapMatrix.length * mapMatrix[0].length,
                  itemBuilder: (BuildContext context, int index) {
                    int row = index ~/ mapMatrix[0].length;
                    int col = index % mapMatrix[0].length;
                    return GridTile(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _getBackgroundColor(row, col),
                          padding: EdgeInsets.zero,
                        ),
                        onPressed: () {
                          if (mapMatrix[row][col] != '0' &&
                              mapMatrix[row][col] != 'U' &&
                              mapMatrix[row][col] != '3') {
                            setState(() {
                              lastClickedRow = row;
                              lastClickedCol = col;
                            });
                          }
                        },
                        child: Text(
                          mapMatrix[row][col],
                          style: TextStyle(
                            fontSize: cellSize / 3,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  "Distance to travel: ${getPathDistance().toString()} mt"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  calculateAndDisplayPath();
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).highlightColor,
                  shadowColor: Theme.of(context).colorScheme.tertiary,
                  elevation: 5,
                ),
                child: const Text('Navigate!'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 8.0,
                right: 30,
                left: 30,
              ),
              child: ElevatedButton(
                onPressed: () => setState(() {
                  path.clear();
                }),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  shadowColor: Theme.of(context).colorScheme.secondary,
                  elevation: 5,
                ),
                child: const Text('Reset Path'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double getPathDistance() {
    if (path.isEmpty) return 0;

    return path.length
        .toDouble(); // TODO: change this based on each node weight -> now is 1mt per node
  }

  List<List<String>> _parseInput(String input) {
    List<List<String>> matrix = [];
    List<String> lines = input.trim().split('\n');

    bool userPlaced = false;
    for (var line in lines) {
      List<String> row = [];
      for (var char in line.split('')) {
        if (char == '1' && !userPlaced) {
          row.add('U');
          userPlaced = true;
        } else {
          row.add(char);
        }
      }
      matrix.add(row);
    }
    return matrix;
  }

  Color _getBackgroundColor(int row, int col) {
    String cellValue = mapMatrix[row][col];
    if (path.contains(Point(row, col))) {
      return Colors.cyan;
    } else if (lastClickedRow == row && lastClickedCol == col) {
      return Colors.orange;
    } else {
      return _getColor(cellValue);
    }
  }

  Color _getColor(String char) {
    switch (char) {
      case '1':
        return Colors.green;
      case '0':
        return Colors.red;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.purple;
      case 'X':
        return const Color.fromARGB(255, 136, 184, 176);
      case 'U':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}
