-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html
-- After the guard changes, the step ProB took no longer applies: the proof is kept,
-- marked broken, and ProB discharges the obligation on its own.
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
    when
      @grd1 n < 3
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  prove = 'inc/inv1/INV',
  tactics = {
    { 'eh', hyp = "n'=n+1" },
    { action = 'prob' },
  },
  status = 'proved',
  after = { replace = { '@grd1 n < 3', '@grd1 n < 2' }, status = 'discharged', broken = 1, expect = {} },
}
