-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Functions
return {
  files = {
    ['M.mch'] = [[
MACHINE M
CONSTANTS f
PROPERTIES
  f : 1..3 --> NATURAL & f = %x.(x : 1..3 | x * x) & f(2) = 4
  & f : 1..3 >-> NATURAL & f : 1..3 +-> NATURAL & {} : NATURAL >+> NATURAL
END
]],
  },
  expect = {},
}
