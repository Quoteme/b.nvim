-- https://www3.hhu.de/stups/handbook/rodin/current/html/generated_proof_obligations.html
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
  hover = { 4, 4 },
  shows = { '```eventb\n@inv1 n ≤ 3\n```', '`@inv1` is an invariant of `m0`.', '✓ `INITIALISATION/inv1/INV`', '✗ `inc/inv1/INV` does not hold' },
}
