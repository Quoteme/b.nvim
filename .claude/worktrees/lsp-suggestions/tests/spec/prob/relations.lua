-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Relations
return {
  files = {
    ['M.mch'] = [[
MACHINE M
CONSTANTS r
PROPERTIES
  r = {1 |-> 2, 3 |-> 4} & r : NATURAL <-> NATURAL & dom(r) = {1, 3} & ran(r) = {2, 4}
  & {1} <| r = {1 |-> 2} & {1} <<| r = {3 |-> 4} & r |> {4} = {3 |-> 4} & r |>> {4} = {1 |-> 2}
  & r~ = {2 |-> 1, 4 |-> 3} & r[{1}] = {2} & r <+ {1 |-> 5} = {1 |-> 5, 3 |-> 4} & (r ; r~) = id({1, 3})
END
]],
  },
  expect = {},
}
