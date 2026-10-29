-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- Removing ¬ pushes the negation inwards.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a
axioms
  @axm1 a ∈ ℕ
  theorem @thm1 ¬(a < 0 ∧ a > a)
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'rn' },
  },
  goal = '¬a<0∨¬a>a',
  remaining = 1,
  nodes = { 'remove ¬ in goal' },
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.rn"', 'org.eventb.core.prSValue=""' },
}
