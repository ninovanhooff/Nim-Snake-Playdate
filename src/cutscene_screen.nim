import playdate/api

from navigator import navigate
from screen import Screen

type CutSceneScreen = ref object of Screen


proc newCutsceneScreen*(): CutSceneScreen =
    return CutSceneScreen()

proc finishCallback(state: LuaStatePtr): cint {.cdecl, raises: [].} =
    let argCount = playdate.lua.getArgCount()
    playdate.system.logToConsole(fmt"Nim callback with {argCount} argument(s)")

    try: 
        for i in countup(1, argCount): # Lua indices start from 1...
            let argType = playdate.lua.getArgType(i.cint)

            case argType:
                of kTypeBool:
                    let value = playdate.lua.getArgBool(i)
                    playdate.system.logToConsole(fmt"Argument {i} is a bool: {value}")
                of kTypeFloat:
                    let value = playdate.lua.getArgFloat(i)
                    playdate.system.logToConsole(fmt"Argument {i} is a float: {value}")
                of kTypeInt:
                    let value = playdate.lua.getArgInt(i)
                    playdate.system.logToConsole(fmt"Argument {i} is an int: {value}")
                of kTypeString:
                    let value = playdate.lua.getArgString(i)
                    playdate.system.logToConsole(fmt"Argument {i} is a string: {value}")
                of kTypeNil:
                    let isNil = playdate.lua.argIsNil(i)
                    playdate.system.logToConsole(fmt"Argument {i} is nil: {isNil}")
                else:
                    playdate.system.logToConsole(fmt"Argument {i} is not a recognized type.")
    except:
        playdate.system.logToConsole(getCurrentExceptionMsg())

    playdate.system.logToConsole("cutscene finished. Restarting cutscene")
    navigate(newCutsceneScreen())
    
    return 0

method init*(screen: CutSceneScreen) {.locks:0.} =
    try:
        playdate.lua.pushFunction(finishCallback)
        playdate.lua.callFunction("StartPanelsExample", 1)
    except:
        playdate.system.logToConsole("couldn't init cutscene")

method update*(screen: CutSceneScreen): int =
    playdate.display.setRefreshRate(30)
    playdate.lua.callFunction("UpdatePanels", 0)
    return 1
