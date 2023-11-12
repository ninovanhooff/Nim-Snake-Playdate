import playdate/api
import strformat

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"

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

type Game = ref object
    snake: Snake
    board: Board

type GameViewState = ref object
    numPartsDrawn: int

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



var game: Game
var gameViewState: GameViewState

var font: LCDFont

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

proc update(): int =
    # playdate is the global PlaydateAPI instance, available when playdate/api is imported
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

    if kButtonA in buttonsState.pushed:
        samplePlayer.play(1, 1.0)

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
    
    gameViewState.numPartsDrawn = snake.parts.len

    return 1

proc catchingUpdate(): int = 
    try:
        return update()
    except:
        let exception = getCurrentException()
        var message: string = ""
        try: 
            message = &"{getCurrentExceptionMsg()}\n{exception.getStackTrace()}\nFATAL EXCEPTION. STOP."
        except:
            message = getCurrentExceptionMsg() & exception.getStackTrace()
            playdate.system.error(message) # this will stop the program
            return 0 # code not reached

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [ValueError].} =
    if event == kEventInit:
        let initialSnake = Snake(parts: @[(x: 8, y:5), (x: 9, y:5), (x: 10, y:5)])
        var initialBoard : Board
        initialBoard[3][3] = tApple
        echo initialBoard[3][3]
        game = Game(snake: initialSnake, board: initialBoard)
        drawBoard(initialBoard)
        gameViewState = GameViewState(numPartsDrawn: 0)


        playdate.display.setRefreshRate(2)

        # Errors are handled through exceptions
        try:
            samplePlayer = playdate.sound.newSamplePlayer("/audio/jingle")
        except:
            playdate.system.logToConsole(getCurrentExceptionMsg())
        # Inline try/except
        filePlayer = try: playdate.sound.newFilePlayer("/audio/finally_see_the_light") except: nil

        filePlayer.play(0)

        # Add a checkmark menu item that plays a sound when switched and unpaused
        discard playdate.system.addCheckmarkMenuItem("Checkmark", false,
            proc(menuItem: PDMenuItemCheckmark) =
                samplePlayer.play(1, 1.0)
        )

        font = try: playdate.graphics.newFont(FONT_PATH) except: nil
        playdate.graphics.setFont(font)

        # Set the update callback
        playdate.system.setUpdateCallback(catchingUpdate)

# Used to setup the SDK entrypoint
initSDK()