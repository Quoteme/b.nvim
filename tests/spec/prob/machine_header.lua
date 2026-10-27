-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Machine_header
return {
  open = 'M.mch',
  files = {
    ['C.mch'] = [[
MACHINE C
CONSTANTS k
PROPERTIES k = 3
END
]],
    ['M.mch'] = [[
MACHINE M(p)
CONSTRAINTS p : NATURAL
SEES C
DEFINITIONS twice(z) == 2 * z
VARIABLES v
INVARIANT v : NATURAL
ASSERTIONS v >= 0
INITIALISATION v := twice(k) + p
END
]],
  },
  expect = {},
}
