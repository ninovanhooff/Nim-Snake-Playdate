import sugar
import sequtils
import playdate/api

from screen import Screen

var platerSprite: LCDBitmap = nil
const FPS = 50
const frameMS: uint = uint((5000/FPS.toFloat()).toInt())
let gfx = playdate.graphics

playdate.display.setRefreshRate(FPS)

const location = "DEVICE"


let W = playdate.display.getWidth()
let H = playdate.display.getHeight()
let CW = W/2
let CH = H/2

let testImage: LCDBitmap = try: gfx.newBitmap("/images/nim_logo") except: nil
let testBack = try: gfx.newBitmap( "Images/background" ) except: nil
let testSprite = try: gfx.newBitmap("Images/playerImage") except: nil

type TestLambda = () -> int
type NamedTestLambda = tuple[name: string, lambda: TestLambda]

type BenchScreen* = ref object of Screen

proc now(): uint = playdate.system.getCurrentTimeMilliseconds

let fDrawLineDiagonal: TestLambda = 
    () => (gfx.drawLine(0,0,W,H, 1, kColorBlack) ; return 1)



var testNil: TestLambda = () => 1


var funcs: seq[NamedTestLambda] = @[
    (name: "nil", lambda: testNil),
    (name: "drawDiagonal", lambda: fDrawLineDiagonal),
]

var start = 0
var count = 0
var done: bool = false
var cmd = 0 # different from lua because 0-based indexing in Nim
let max = funcs.len

method init*(bench: BenchScreen) =
    cmd = 0

method  update*(bench: BenchScreen): int = 
    if cmd == 0:
            playdate.system.logToConsole("#, BENCH, CALL")

    if (cmd >= 0 and cmd < max):
        let (_, lambda) = funcs[cmd]
        let endTime = now() + frameMS
        while now() < endTime:
            lambda()
            count += 1
        
        done = true

    if done:
        playdate.system.logToConsole(fmt"${funcs[cmd].name} ${count}")


    return 1
    







