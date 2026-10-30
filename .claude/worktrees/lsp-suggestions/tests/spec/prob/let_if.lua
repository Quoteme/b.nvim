-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#LET_and_IF-THEN-ELSE
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES
  (LET x BE x = 1 IN x + 1 END) = 2 & (IF 1 = 1 THEN 2 ELSE 3 END) = 2
END
]],
  },
  expect = {},
}
