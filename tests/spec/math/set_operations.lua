-- https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#a0000000375
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a b
axioms
  @axm1 a ⊆ ℕ ∧ b ⊂ ℕ ∧ (a ⊈ ∅ ∨ b ⊄ ℕ)
  @axm2 (a ∪ b) ∖ (a ∩ b) ∈ ℙ(ℕ) ∧ ℙ1(a) ⊆ ℙ(a)
  @axm3 finite(a ∩ 1 ‥ 3) ∧ card(1 ‥ 3) = 3
end
]],
  },
  expect = {},
}
