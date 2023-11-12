import playdate/api
import strformat

const 
    ROWS = 100
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

type Game* = ref object
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

proc `[]`(b: Board, r, c: int): Tile =
  b[r][c]

proc drawBoard(board: Board) {.raises: [ValueError].} =
    for y, row in board:
        for x, tile in row:
            playdate.system.logToConsole(fmt" {x} {y} {tile}")
            if tile == tApple:
                let pixelCoords = boardToPixel((x,y))
                playdate.graphics.fillRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorBlack)

proc gameUpdate*(game: Game): int =
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

    if board[newHead.x][newHead.y] == tApple:
        # mark apple as eaten
        game.board[newHead.x][newHead.y] = tEmpty
        var pixelCoords = snakePartToPixel(newHead)
        playdate.graphics.fillRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorWhite)
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

proc gameInit*(): Game =
    let initialSnake = Snake(parts: @[(x: 8, y:5), (x: 9, y:5), (x: 10, y:5)])
    var initialBoard : Board
    initialBoard[3][3] = tApple
    echo initialBoard[3][3]
    drawBoard(initialBoard)
    return Game(snake: initialSnake, board: initialBoard)