type Screen* = ref object of RootObj

method init*(screen: Screen) {.base, locks:0, raises: [].} =
  discard

method update*(self: Screen): int {.base.} = 0
##[ returns 0 if no screen update is needed or 1 if there is.
  ]##    