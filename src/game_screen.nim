{.experimental: "codeReordering".}

import playdate/api
import strformat
import std/random
from navigator import navigate
from screen import Screen

const 
    ROWS = 8
    COLS = 14

type
    Tile = enum
        tEmpty
        tApple
        tWall
    Col = array[ROWS, Tile]
    Board = array[COLS, Col]

    SnakePart = tuple
        x: int
        y: int

    Direction = enum
        dUp
        dDown
        dLeft
        dRight


type Snake = ref object
    parts: seq[SnakePart]
    moveDirection: Direction

type Point = tuple
    x: int
    y: int


type GameScreen* = ref object of Screen
    snake: Snake
    board: Board

proc head(self: Snake): SnakePart =
    return self.parts[self.parts.len - 1]

proc moveSigns(self: Direction): (int, int) =
    result = case self:
        of dDown:
            (0, 1)
        of dUp:
            (0, -1)
        of dLeft:
            (-1, 0)
        of dRight:
            (1, 0)

proc boardToPixel(boardPoint: Point): Point =
    (x: boardPoint.x * 25, y: boardPoint.y * 25)

proc snakePartToPixel(self: SnakePart): Point = 
    boardToPixel(self)

proc randomizeApple(board: var Board) =
    let 
        x = rand(COLS-1)
        y = rand(ROWS-1)
    board[x][y] = tApple
    try: playdate.system.logToConsole(fmt"Apple at {x}, {y}") except: discard
    drawApple(x, y)
    
proc drawApple(x: int, y: int) =
    let pixelCoords = boardToPixel((x,y))
    playdate.graphics.fillRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorBlack)

proc drawBoard(board: Board) {.raises: [].} =
    for y, row in board:
        for x, tile in row:
            if tile == tApple:
                drawApple(x, y)

proc newGame*(): GameScreen {.raises:[].} =
    let initialSnake = Snake(parts: @[(x: 8, y:5), (x: 9, y:5), (x: 10, y:5)])
    var initialBoard : Board
    randomizeApple(initialBoard)
    return GameScreen(snake: initialSnake, board: initialBoard)

method init*(screen: GameScreen) =
    playdate.display.setRefreshRate(2)
    playdate.graphics.clear(kColorWhite)
    drawBoard(screen.board)

method update*(game: GameScreen): int =
    let buttonsState = playdate.system.getButtonsState()
    var snake = game.snake
    var board = game.board

    if kButtonRight in buttonsState.pushed:
        snake.moveDirection = dRight
    if kButtonLeft in buttonsState.pushed:
        snake.moveDirection = dLeft
    if kButtonUp in buttonsState.pushed:
        snake.moveDirection = dUp
    if kButtonDown in buttonsState.pushed:
        snake.moveDirection = dDown
    let oldHead = snake.head()
    let oldTail = snake.parts[0]
    let signs = moveSigns(snake.moveDirection)
    let newHead: SnakePart = (x: oldHead.x + signs[0], y: oldHead.y + signs[1])
    snake.parts.add(newHead)
    playdate.system.logToConsole(fmt"newHead {newHead.x}")

    let tileAtHead = block:
        try:
            board[newHead.x][newHead.y]
        except:
            tWall

    if tileAtHead == tWall:
        playdate.system.logToConsole("Hit the wall. Restarting Snake")
        navigate(newGame())
        return

    if tileAtHead == tApple:
        # mark apple as eaten
        game.board[newHead.x][newHead.y] = tEmpty
        var pixelCoords = snakePartToPixel(newHead)
        playdate.graphics.fillRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorWhite)
        randomizeApple(game.board)
        # do NOT delete the tail from snake parts in this case, effectively growing the snake
    else:
        snake.parts.delete(0)

    playdate.system.drawFPS(0, 0)


    var part = oldTail
    var pixelCoords = snakePartToPixel(part)
    playdate.graphics.fillRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorWhite)
    part = snake.head()
    pixelCoords = snakePartToPixel(part)
    playdate.graphics.drawRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorBlack)

    return 1
