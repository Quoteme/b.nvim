-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html
-- Rewriting with the action's equality, then ProB closes the goal.
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
  remaining = 0,
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.eq:1"', 'org.eventb.core.prDisplay="eh with n\'=n+1"', 'de.prob.eventb.disprover.core.disproverReasoner' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
