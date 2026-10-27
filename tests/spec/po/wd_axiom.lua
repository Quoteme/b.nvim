-- https://www3.hhu.de/stups/handbook/rodin/current/html/well_definedness_proof_obligations.html#well_definedness_of_axioms
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
axioms
  @axm1 n = card(ℕ)
end
]],
  },
  expect = { "c0.mch:4: axm1/WD" },
}
