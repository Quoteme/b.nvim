-- https://www3.hhu.de/stups/handbook/rodin/current/html/generated_proof_obligations.html
return {
  action = 'prob.showPOs',
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
end
]],
  },
  expect = {},
  quickfix = { "m0.mch:6: INITIALISATION/inv1/INV" },
}
