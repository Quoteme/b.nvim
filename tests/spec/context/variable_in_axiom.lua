-- https://www3.hhu.de/stups/handbook/rodin/current/html/visibility_of_identifiers.html
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 x ∈ ℕ
end
]],
  },
  expect = { "c0.mch:3: Identifier 'x' has not been declared" },
}
