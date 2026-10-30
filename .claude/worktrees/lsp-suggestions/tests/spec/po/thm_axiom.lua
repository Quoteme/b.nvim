-- https://www3.hhu.de/stups/handbook/rodin/current/html/generated_proof_obligations.html
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
axioms
  @axm1 n ∈ 1 ‥ 3
  theorem @thm1 n > 1
end
]],
  },
  expect = { "c0.mch:5: thm1/THM" },
}
