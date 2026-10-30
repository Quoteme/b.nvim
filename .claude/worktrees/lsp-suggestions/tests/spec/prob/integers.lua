-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Integers
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES
  2 + 3 * 4 - 1 = 13 & 7 / 2 = 3 & 7 mod 2 = 1 & 2 ** 3 = 8 & succ(1) = 2 & pred(1) = 0
  & max({1, 2}) = 2 & min({1, 2}) = 1 & SIGMA(z).(z : 1..3 | z) = 6 & PI(z).(z : 1..3 | z) = 6
  & MAXINT >= 1 & MININT <= -1 & 1 : INTEGER & 1 : NATURAL1
END
]],
  },
  expect = {},
}
