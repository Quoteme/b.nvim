-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#constants_and_axioms
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
end
]],
  },
  expect = { "c0.mch:2: Constant 'n' has no type" },
}
