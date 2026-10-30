-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#constant_relations
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 (id ⦂ ℙ(ℤ × ℤ))[{1}] = {1}
  @axm2 prj1(1 ↦ 2) = 1 ∧ prj2(1 ↦ 2) = 2
end
]],
  },
  expect = {},
}
