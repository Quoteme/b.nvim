-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#operations_on_relations
return {
  files = {
    ['c0.mch'] = [[
context c0
constants r s
axioms
  @axm1 r = {1 ↦ 2} ∧ s = {2 ↦ 3}
  @axm2 r ; s = s ∘ r ∧ r∼ = {2 ↦ 1} ∧ r  s = r ∪ s
  @axm3 r ⊗ r = {1 ↦ (2 ↦ 2)} ∧ r ∥ s = {(1 ↦ 2) ↦ (2 ↦ 3)}
end
]],
  },
  expect = {},
}
