-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#variables_and_invariants
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
end
]],
  },
  expect = { "m0.mch:2: Variable 'n' has no type" },
}
