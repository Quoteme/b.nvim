-- https://www3.hhu.de/stups/handbook/rodin/current/html/arithmetic.html#minimum_and_maximum
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 min({1, 2}) = 1 ∧ max({1, 2}) = 2
end
]],
  },
  expect = {},
}
