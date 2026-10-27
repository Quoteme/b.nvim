-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#quantified_predicates
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 ∀x·x ∈ ℕ ⇒ x + 1 > x
  @axm2 ∃x, y·x ∈ ℤ ∧ y ∈ ℤ ∧ x < y
  @axm3 ∀x ⦂ ℤ·x = x
end
]],
  },
  expect = {},
}
