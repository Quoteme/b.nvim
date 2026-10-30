-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#constants_and_axioms
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
axioms
  @axm1 n ∈ ℕ
  theorem @thm1 n ≥ 0
end
]],
  },
  expect = {},
}
