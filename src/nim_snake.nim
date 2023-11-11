import playdate/api

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"
const NIM_IMAGE_PATH = "/images/nim_logo"
const PLAYDATE_NIM_IMAGE_PATH = "/images/playdate_nim"

type
    SnakePart = tuple[x: int, y: int]
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


type Game = ref object
    snake: Snake

type GameViewState = ref object
    numPartsDrawn: int


var game: Game
var gameViewState: GameViewState

var font: LCDFont

var playdateNimBitmap: LCDBitmap
var nimLogoBitmap: LCDBitmap

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

proc update(): int =
    # playdate is the global PlaydateAPI instance, available when playdate/api is imported
    let buttonsState = playdate.system.getButtonsState()
    var snake = game.snake

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

    let head = snake.head()
    let signs = moveSigns(snake.moveDirection)
    playdate.system.logToConsole(fmt"len before { snake.parts.len } moveDirection { snake.moveDirection }")
    snake.parts.add((x: head.x + signs[0], y: head.y + signs[1]))

    playdate.system.drawFPS(0, 0)

    playdate.system.logToConsole(fmt"{gameViewState.numPartsDrawn}, {snake.parts.len}")

    for i in countup(gameViewState.numPartsDrawn, snake.parts.len - 1):
        let part = snake.parts[i]
        let pixelCoords = snakePartToPixel(part)
        playdate.graphics.drawRect(pixelCoords.x, pixelCoords.y, 20, 20, kColorBlack)
    
    gameViewState.numPartsDrawn = snake.parts.len

    return 1

import std/json
type
    Equip = ref object
        name: string
        damage: int
    Entity = ref object
        name: string
        enemy: bool
        health: int
        equip: seq[Equip]

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =
    if event == kEventInit:
        let initialSnake = Snake(parts: @[(x: 10, y:5)])
        game = Game(snake: initialSnake)
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

        playdateNimBitmap = try: playdate.graphics.newBitmap(PLAYDATE_NIM_IMAGE_PATH) except: nil
        nimLogoBitmap = try: playdate.graphics.newBitmap(NIM_IMAGE_PATH) except: nil

        try:
            # Decode a JSON string to an object, type safe!
            let jsonString = playdate.file.open("/json/data.json", kFileRead).readString()
            let obj = parseJson(jsonString).to(Entity)
            playdate.system.logToConsole(fmt"JSON decoded: {obj.repr}")
            # Encode an object to a JSON string, %* is the encode operator
            playdate.system.logToConsole(fmt"JSON encoded: {(%* obj).pretty}")

            let faultyString = playdate.file.open("/json/error.json", kFileRead).readString()
            # This generates an exception
            discard parseJson(faultyString).to(Entity)
        except:
            playdate.system.logToConsole("This below is an expected error:")
            playdate.system.logToConsole(getCurrentExceptionMsg())

        # Set the update callback
        playdate.system.setUpdateCallback(update)

# Used to setup the SDK entrypoint
initSDK()