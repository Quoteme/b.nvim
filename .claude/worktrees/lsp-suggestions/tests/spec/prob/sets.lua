-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Sets
return {
  files = {
    ['M.mch'] = [[
MACHINE M
SETS COLOUR = {red, green}; ID
PROPERTIES
  {1, 2} \/ {3} /\ {3} = {1, 2, 3} & {1} <: NATURAL & {1} <<: NAT & POW({1}) = {{}, {1}}
  & card({x | x : 1..4 & x mod 2 = 0}) = 2 & union({{1}, {2}}) = {1, 2} & red : COLOUR
END
]],
  },
  expect = {},
}
