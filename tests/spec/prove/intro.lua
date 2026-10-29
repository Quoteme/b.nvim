-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- ∀ goal, ⇒ goal and ∧ goal split the goal; ProB proves what is left.
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  theorem @thm1 ∀x·x ∈ ℕ ⇒ x + 1 ∈ ℕ1 ∧ x ≥ 0
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'allI' },
    { 'impI' },
    { 'conj' },
    { action = 'proball' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { '∀ goal (frees x)', '⇒ goal', '∧ goal', 'ProB (no enumeration / all cases checked)' },
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.allI"', 'org.eventb.core.prRID="org.eventb.core.seqprover.conj:0"', 'org.eventb.core.prFresh="x"' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
