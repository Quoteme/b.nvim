-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#membership
return {
  files = {
    ['c0.mch'] = [[
context c0
sets S
constants s
axioms
  @axm1 s ∈ S
  @axm2 s ∉ ∅ ∧ s ∈ {s}
end
]],
  },
  expect = {},
}
