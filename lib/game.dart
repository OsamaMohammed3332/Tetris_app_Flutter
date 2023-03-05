import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main.dart';
import 'dart:async';
import 'dart:math';
import 'block.dart';
import 'sub_block.dart';

enum Collision { LANDED, LANDED_BLOCK, HIT_BLOCK, HIT_WALL, NONE }

const BLOCKS_X = 10;
const BLOCKS_Y = 20;
const REFRESH_RATE = 300;
const GAME_AREA_BORDER_WIDTH = 2.0;
const SUB_BLOCK_EDGE_WIDTH = 2.0;

class Game extends StatefulWidget {
  Game({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => GameState();
}

class GameState extends State<Game> {
  late double subBlockWidth;
  Duration duration = const Duration(milliseconds: REFRESH_RATE);

  final GlobalKey _keyGameArea = GlobalKey();
  BlockMovement? action;
  Block? block;
  Timer? timer;
  bool isGameOver = false;
  late List<SubBlock> oldSubBlocks;

  Block? getNewBlock() {
    int blockType = Random().nextInt(7);
    int orientationIndex = Random().nextInt(4);

    switch (blockType) {
      case 0:
        return IBlock(orientationIndex);
      case 1:
        return JBlock(orientationIndex);
      case 2:
        return LBlock(orientationIndex);
      case 3:
        return OBlock(orientationIndex);
      case 4:
        return TBlock(orientationIndex);
      case 5:
        return SBlock(orientationIndex);
      case 6:
        return ZBlock(orientationIndex);
      default:
        return null;
    }
  }

  void startGame() {
    Provider.of<Data>(context).setIsPlaying(true);
    Provider.of<Data>(context).setScore(0);
    isGameOver = false;
    oldSubBlocks = <SubBlock>[];
    RenderBox renderBoxGame =
        _keyGameArea.currentContext!.findRenderObject() as RenderBox;
    subBlockWidth =
        (renderBoxGame.size.width - GAME_AREA_BORDER_WIDTH * 2) / BLOCKS_X;

    Provider.of<Data>(context).setNextBlock(getNewBlock()!);

    block = getNewBlock()!;

    timer = Timer.periodic(duration, onPlay);
  }

  void endGame() {
    Provider.of<Data>(context).setIsPlaying(false);
    timer!.cancel();
  }

  void onPlay(Timer timer) {
    var status = Collision.NONE;

    setState(() {
      if (action != null) {
        if (!checkOnEdge(action as BlockMovement)) {
          block!.move(action!);
        }
      }

      for (var oldSubBlock in oldSubBlocks) {
        for (var subBlock in block!.subBlocks) {
          var x = block!.x + subBlock.x;
          var y = block!.y + subBlock.y;
          if (x == oldSubBlock.x && y == oldSubBlock.y) {
            switch (action) {
              case BlockMovement.LEFT:
                block!.move(BlockMovement.RIGHT);
                break;
              case BlockMovement.RIGHT:
                block!.move(BlockMovement.LEFT);
                break;
              case BlockMovement.ROTATE_CLOCKWISE:
                block!.move(BlockMovement.ROTATE_COUNTER_CLOCKWISE);
                break;
              default:
                break;
            }
          }
        }
      }

      if (!checkAtBottom()) {
        if (!checkAboveBlock()) {
          block!.move(BlockMovement.DOWN);
        } else {
          status = Collision.LANDED_BLOCK;
        }
      } else {
        status = Collision.LANDED;
      }

      if (status == Collision.LANDED_BLOCK && block!.y < 0) {
        isGameOver = true;
        endGame();
      } else if (status == Collision.LANDED ||
          status == Collision.LANDED_BLOCK) {
        block!.subBlocks.forEach((subBlock) {
          subBlock.x += block!.x;
          subBlock.y += block!.y;
          oldSubBlocks.add(subBlock);
        });
        block = Provider.of<Data>(context).nextBlock;
        Provider.of<Data>(context).setNextBlock(getNewBlock()!);
      }

      action = null;
      updateScore();
    });
  }

  void updateScore() {
    var combo = 1;
    Map<int, int> rows = {};
    List<int> rowsToBeRemoved = [];

    oldSubBlocks.forEach((subBlock) {
      rows.update(subBlock.y, (value) => ++value, ifAbsent: () => 1);
    });

    rows.forEach((rowNum, count) {
      if (count == BLOCKS_X) {
        Provider.of<Data>(context).addScore(combo++);
        rowsToBeRemoved.add(rowNum);
      }
    });

    if (rowsToBeRemoved.length > 0) {
      removeRows(rowsToBeRemoved);
    }
  }

  void removeRows(List<int> rowsToBeRemoved) {
    rowsToBeRemoved.sort();
    rowsToBeRemoved.forEach((rowNum) {
      oldSubBlocks.removeWhere((subBlock) => subBlock.y == rowNum);
      oldSubBlocks.forEach((subBlock) {
        if (subBlock.y < rowNum) {
          ++subBlock.y;
        }
      });
    });
  }

  bool checkAtBottom() {
    return block!.y + block!.height == BLOCKS_Y;
  }

  bool checkAboveBlock() {
    for (var oldSubBlock in oldSubBlocks) {
      for (var subBlock in block!.subBlocks) {
        var x = block!.x + subBlock.x;
        var y = block!.y + subBlock.y;
        if (x == oldSubBlock.x && y + 1 == oldSubBlock.y) {
          return true;
        }
      }
    }
    return false;
  }

  bool checkOnEdge(BlockMovement action) {
    return (action == BlockMovement.LEFT && block!.x <= 0) ||
        (action == BlockMovement.RIGHT && block!.x + block!.width >= BLOCKS_X);
  }

  Widget getPositionedSquareContainer(Color color, int x, int y) {
    return Positioned(
      left: x * subBlockWidth,
      top: y * subBlockWidth,
      child: Container(
        width: subBlockWidth - SUB_BLOCK_EDGE_WIDTH,
        height: subBlockWidth - SUB_BLOCK_EDGE_WIDTH,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(3.0)),
        ),
      ),
    );
  }

  Widget? drawBlocks() {
    if (block == null) return null;
    List<Positioned> subBlocks = [];

    // Current block
    block!.subBlocks.forEach((subBlock) {
      subBlocks.add(getPositionedSquareContainer(
              subBlock.color, subBlock.x + block!.x, subBlock.y + block!.y)
          as Positioned);
    });

    oldSubBlocks.forEach((oldSubBlock) {
      subBlocks.add(getPositionedSquareContainer(
          oldSubBlock.color, oldSubBlock.x, oldSubBlock.y) as Positioned);
    });

    if (isGameOver) {
      subBlocks.add(getGameOverRect() as Positioned);
    }
    return Stack(
      children: subBlocks,
    );
  }

  Widget getGameOverRect() {
    return Positioned(
      left: subBlockWidth * 1.0,
      top: subBlockWidth * 6.0,
      child: Container(
        width: subBlockWidth * 8.0,
        height: subBlockWidth * 3.0,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.all(Radius.circular(10.0))),
        child: const Text(
          'Game Over',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: ((details) {
        if (details.delta.dx > 0) {
          action = BlockMovement.RIGHT;
        } else {
          action = BlockMovement.LEFT;
        }
      }),
      onTap: () {
        action = BlockMovement.ROTATE_CLOCKWISE;
      },
      child: AspectRatio(
        aspectRatio: BLOCKS_X / BLOCKS_Y,
        child: Container(
          key: _keyGameArea,
          decoration: BoxDecoration(
            color: Colors.indigo[800],
            border: Border.all(
              width: GAME_AREA_BORDER_WIDTH,
              color: Colors.indigoAccent,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
          ),
          child: drawBlocks(),
        ),
      ),
    );
  }
}
