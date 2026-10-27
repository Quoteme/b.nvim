-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#consistency_proof_obligations
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    then
      @act1 n ≔ −1
  end
end
]],
  },
  expect = { "m0.mch:6: INITIALISATION/inv1/INV" },
}
