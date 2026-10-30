-- https://www3.hhu.de/stups/handbook/rodin/current/html/booleans.html
return {
  files = {
    ['c0.mch'] = [[
context c0
constants b
axioms
  @axm1 b ∈ BOOL
  @axm2 b = bool(1 < 2) ∧ BOOL = {TRUE, FALSE}
end
]],
  },
  expect = {},
}
