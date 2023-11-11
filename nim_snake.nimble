# Package

version       = "0.1.0"
author        = "Nino van Hooff"
description   = "An example application using the Playdate Nim bindings"
license       = "MIT"
srcDir        = "src"
bin           = @["nim_snake"]


# Dependencies

requires "nim >= 1.6.10"
requires "playdate"
include playdate/build/nimble
