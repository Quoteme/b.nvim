-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Records
return {
  files = {
    ['M.mch'] = [[
MACHINE M
CONSTANTS p
PROPERTIES
  p = rec(x : 1, y : TRUE) & p : struct(x : NATURAL, y : BOOL) & p'x = 1
END
]],
  },
  expect = {},
}
