-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#carrier_sets
return {
  files = {
    ['c0.mch'] = [[
context c0
sets COLOUR
constants red green
axioms
  @axm1 partition(COLOUR, {red}, {green})
end
]],
  },
  expect = {},
}
