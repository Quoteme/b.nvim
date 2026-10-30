-- https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#a0000000389
return {
  files = {
    ['c0.mch'] = [[
context c0
constants x
axioms
  @axm1 x = union({{1}, {2}}) ∪ inter({{1, 2}, {2}})
  @axm2 x = (⋃ i · i ∈ 1 ‥ 2 ∣ {i}) ∪ (⋂ i · i ∈ 1 ‥ 2 ∣ 1 ‥ 2)
end
]],
  },
  expect = {},
}
