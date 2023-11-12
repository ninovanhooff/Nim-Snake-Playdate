import playdate/api
import strformat
import screen
from game_screen import newGame, Game

const FONT_PATH = "/System/Fonts/Asheville-Sans-14-Bold.pft"

var activeScreen : Screen

var font: LCDFont

var samplePlayer: SamplePlayer
var filePlayer: FilePlayer

proc catchingUpdate(): int = 
    try:
        return activeScreen.update()
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
        activeScreen = newGame()
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