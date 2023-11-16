{.push raises: [].}

import screen

var activeScreen: Screen

proc getActiveScreen*(): Screen =
    return activeScreen

proc navigate*(toScreen: Screen) {.raises: [].} =
    activeScreen = toScreen
    activeScreen.init()