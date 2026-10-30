-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#lambda
return {
  files = {
    ['c0.mch'] = [[
context c0
constants sq
axioms
  @axm1 sq = (λx · x ∈ ℤ ∣ x ∗ x)
  @axm2 sq(3) = 9
end
]],
  },
  expect = {},
}
