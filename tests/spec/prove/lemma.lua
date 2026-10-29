-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- ah adds a lemma, proved on its own branch and used as a hypothesis on the other.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a
axioms
  @axm1 a ∈ ℤ
  theorem @thm1 a * a ≥ 0
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'ah', input = 'a ≥ 0 ∨ a < 0' },
    { action = 'goto', node = '2' },
    { 'disjE', hyp = 'a≥0∨a<0' },
    { action = 'proball' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { 'ah (a≥0∨a<0)', 'case distinction (a≥0∨a<0)' },
  bpr = { 'org.eventb.core.prPredRef name=".pred"', 'org.eventb.core.prRID="org.eventb.core.seqprover.cut"' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
