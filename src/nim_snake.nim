import std/strutils

import playdate/api
import strformat
import screen
import navigator
import bench
from cutscene_screen import newCutsceneScreen
from game_screen import newGame

var firstUpdate: bool = true

proc catchingUpdate(): int = 
    try:
        if(firstUpdate):
            navigate(newCutsceneScreen())
            firstUpdate = false

        return getActiveScreen().update()
    except:
        let exception = getCurrentException()
        var message: string = ""
        try: 
            message = &"{getCurrentExceptionMsg()}\n{exception.getStackTrace()}\nFATAL EXCEPTION. STOP."
            # replace line number notation from (90) to :90, which is more common and can be picked up as source link
            message = message.replace('(', ':')
            message = message.replace(")", "")
        except:
            message = getCurrentExceptionMsg() & exception.getStackTrace()

        playdate.system.error(message) # this will stop the program
        return 0 # code not reached

# This is the application entrypoint and event handler
proc handler(event: PDSystemEvent, keycode: uint) {.raises: [].} =

    if event == kEventInitLua:
        # # Set the update callback
        # # An active screen is required at all times
        # try:
        #     navigate(newCutsceneScreen())
        # except:
        #     playdate.system.logToConsole("couldn't navigate")

        playdate.system.setUpdateCallback(catchingUpdate)

# Used to setup the SDK entrypoint
initSDK()