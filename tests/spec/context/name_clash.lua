-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#carrier_sets
return {
  files = {
    ['c0.mch'] = [[
context c0
sets S
constants S
end
]],
  },
  expect = { "c0.mch:3: 'S' is already declared" },
}
