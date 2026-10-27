-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#equality
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a
axioms
  @axm1 a ∈ ℤ
  @axm2 a = a ∧ ¬(a ≠ a)
end
]],
  },
  expect = {},
}
