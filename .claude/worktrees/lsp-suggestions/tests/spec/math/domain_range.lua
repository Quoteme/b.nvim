-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#domain_and_range_restrictions
return {
  files = {
    ['c0.mch'] = [[
context c0
constants r
axioms
  @axm1 r = {1 ↦ 2, 3 ↦ 4}
  @axm2 dom(r) = {1, 3} ∧ ran(r) = {2, 4}
  @axm3 {1} ◁ r = {1 ↦ 2} ∧ {1} ⩤ r = {3 ↦ 4} ∧ r ▷ {4} = {3 ↦ 4} ∧ r ⩥ {4} = {1 ↦ 2}
end
]],
  },
  expect = {},
}
