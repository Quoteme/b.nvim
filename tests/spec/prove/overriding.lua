-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- Function overriding: a case distinction on whether 1 is in the domain of {1 ↦ 2}.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants f
axioms
  @axm1 f ∈ ℕ → ℕ
  theorem @thm1 (f  {1 ↦ 2})(1) = 2
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'funOvr' },
    { action = 'proball' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { 'ovr' },
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.funOvr:1"' },
}
