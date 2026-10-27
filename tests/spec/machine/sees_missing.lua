-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#seeing_a_context
return {
  files = {
    ['m0.mch'] = [[
machine m0 sees c9
end
]],
  },
  expect = { "m0.mch:1: Component 'c9' not found" },
}
