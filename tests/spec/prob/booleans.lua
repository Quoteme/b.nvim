-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Booleans
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES
  bool(1 = 1) = TRUE & BOOL = {TRUE, FALSE}
END
]],
  },
  expect = {},
}
