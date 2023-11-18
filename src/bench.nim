import sugar
import std/random
import std/math
import playdate/api

from navigator import navigate
from screen import Screen
from game_screen import newGame

var platerSprite: LCDBitmap = nil
const FPS = 50
const frameMS: uint = uint((5000/FPS.toFloat()).toInt())

const location = "DEVICE"


var W: int
var H: int
var CW: int
var CH: int

var testImage: LCDBitmap
var testBack: LCDBitmap
var testSprite: LCDBitmap

type TestLambda = () -> (void)
type NamedTestLambda = tuple[name: string, lambda: TestLambda]

type BenchScreen* = ref object of Screen

var gfx: ptr PlaydateGraphics

proc now(): uint = playdate.system.getCurrentTimeMilliseconds

let fNil: TestLambda = () => (discard)

let fDrawLineDiagonal: TestLambda = 
    () => gfx.drawLine(0,0,W,H, 1, kColorBlack)

let fDrawLineHorizontal: TestLambda = 
    () => playdate.graphics.drawLine(0,CH,W,CH, 1, kColorBlack)

let fDrawLineVertical: TestLambda = 
    () => playdate.graphics.drawLine(CW,0,CW,H, 1, kColorBlack)

let fDrawLineRandomDiagonal: TestLambda = 
    () => playdate.graphics.drawLine(0,rand(H),0,rand(H), 1, kColorBlack)

let fDrawLineFillRect: TestLambda = 
    () => playdate.graphics.fillRect(0,CH,W,1, kColorBlack)

let fDrawLineDrawRect: TestLambda = 
    () => playdate.graphics.drawRect(0,CH,W,1, kColorBlack)

proc print(what: string) = 
    playdate.system.logToConsole(what)

let fMathRandomSugar: TestLambda = 
    () => (block:
        discard rand(999)
        (discard)
    )

# in nim, there is no concept of global vs local like in Lua.
let fMathRandomProc: TestLambda = proc() = 
    discard rand(999)
    (discard)

let fMathSinSugar: TestLambda = 
        () => (block:
        discard sin(1.5f)
        (discard)
    )

let fMathSinRandom: TestLambda = proc() =
    discard sin(rand(6f))
    (discard)

let fMathCos: TestLambda = proc() =
    discard cos(1.5f)
    (discard)

let fMathCosRandom: TestLambda = proc() =
    discard cos(rand(6f))
    (discard)

let fMathFloor: TestLambda = proc() =
    discard floor(1.23f)
    (discard)

let fImageSample: TestLambda = proc() =
    discard testImage.get(0,0)
    (discard)


var funcs: seq[NamedTestLambda] = @[
    (name: "nil", lambda: fNil),
    (name: "drawDiagonal", lambda: fDrawLineDiagonal),
    (name: "drawHorizontal", lambda: fDrawLineHorizontal),
    (name: "drawVertical", lambda: fDrawLineVertical),
    (name: "drawRandomDiagonal", lambda: fDrawLineRandomDiagonal),
    (name: "drawLineFillRect", lambda: fDrawLineFillRect),
    (name: "drawLineDrawRect", lambda: fDrawLineDrawRect),
    (name: "mathRandomSugar", lambda: fMathRandomSugar),
    (name: "mathRandomProc", lambda: fMathRandomProc),
    (name: "mathSin", lambda: fMathSinSugar),
    (name: "mathSinRandom", lambda: fMathSinRandom),
    (name: "mathCos", lambda: fMathCos),
    (name: "mathCosRandom", lambda: fMathCosRandom),
    (name: "mathFloor", lambda: fMathFloor),
    (name: "imageSample", lambda: fImageSample),
]

var start = 0
var count = 0
var done: bool = false
var cmd = 0 # different from lua because 0-based indexing in Nim
let max = funcs.len
var logLines: seq[string] = @[]

method init*(bench: BenchScreen) =
    gfx = playdate.graphics
    playdate.display.setRefreshRate(FPS)
    W = playdate.display.getWidth()
    H = playdate.display.getHeight()
    CW = (W/2).toInt()
    CH = (H/2).toInt()
    testImage = try: playdate.graphics.newBitmap("/images/nim_logo") except: nil
    testBack = try: playdate.graphics.newBitmap( "Images/background" ) except: nil
    testSprite = try: playdate.graphics.newBitmap("Images/playerImage") except: nil
    cmd = 0
    count = 0
    done = false

method  update*(bench: BenchScreen): int = 
    if cmd == 0:
            playdate.system.logToConsole(fmt"frameMS: {frameMS}")
            playdate.system.logToConsole("#, BENCH, CALL")

    if (cmd >= 0 and cmd < max):
        let (_, lambda) = funcs[cmd]
        let endTime = now() + frameMS
        while now() < endTime:
            lambda()
            count += 1
        
        done = true

    if done and cmd < max:
        logLines.add(fmt"{funcs[cmd].name} {count}")
        done = false
        count = 0
        cmd += 1

    if cmd >= max and not done:
        gfx.clear(kColorWhite)
        let buttonsState = playdate.system.getButtonsState()
        for line in logLines:
            playdate.system.logToConsole(line)

        done = true

        if kButtonA in buttonsState.pushed:
            navigate(BenchScreen())
            return 0
        


    return 1
    







