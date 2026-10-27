-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Logical_predicates
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES
  1 = 1 & (2 = 2 or 1 = 2) & not(1 = 2) & (1 = 1 => 2 = 2) & (1 = 1 <=> 2 = 2)
  & !x.(x : 1..3 => x > 0) & #y.(y : NATURAL & y > 5)
END
]],
  },
  expect = {},
}
