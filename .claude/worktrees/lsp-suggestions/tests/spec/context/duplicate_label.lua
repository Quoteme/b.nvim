-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#constants_and_axioms
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
axioms
  @axm1 n ∈ ℕ
  @axm1 n < 10
end
]],
  },
  expect = { "c0.mch:5: Label 'axm1' is already used" },
}
