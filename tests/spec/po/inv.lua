-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#consistency_proof_obligations
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ≤ 3
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  expect = { "m0.mch:10: inc/inv1/INV" },
}
