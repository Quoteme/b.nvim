-- https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#partition
return {
  files = {
    ['c0.mch'] = [[
context c0
sets DAY
constants weekday weekend
axioms
  @axm1 partition(DAY, weekday, weekend)
  @axm2 weekday ≠ ∅
end
]],
  },
  expect = {},
}
