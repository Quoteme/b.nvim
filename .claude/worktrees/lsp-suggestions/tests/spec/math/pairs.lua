-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#pairs_and_cartesian_product
return {
  files = {
    ['c0.mch'] = [[
context c0
constants p
axioms
  @axm1 p = 1 ↦ TRUE
  @axm2 p ∈ ℕ × BOOL
end
]],
  },
  expect = {},
}
