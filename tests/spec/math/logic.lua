-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#a0000000349
return {
  files = {
    ['c0.mch'] = [[
context c0
constants p q
axioms
  @axm1 p ∈ BOOL ∧ q ∈ BOOL
  @axm2 (p = TRUE ∧ q = TRUE) ∨ ¬(p = TRUE) ∨ (p = TRUE ⇒ q = TRUE) ∨ (p = TRUE ⇔ q = TRUE)
  @axm3 ⊤ ∧ ¬⊥
end
]],
  },
  expect = {},
}
