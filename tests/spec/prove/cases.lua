-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- Removing ∈ in a hypothesis gives a disjunction, whose cases ProB proves.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a
axioms
  @axm1 a ∈ {1, 2}
  theorem @thm1 a > 0
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'rm', hyp = 'a∈{1,2}' },
    { 'disjE', hyp = 'a=1∨a=2' },
    { 'eh', hyp = 'a=1' },
    { action = 'proball' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { 'remove ∈ in a∈{1,2}', 'case distinction (a=1∨a=2)', 'eh with a=1' },
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.rm"', 'org.eventb.core.prHypAction name="REWRITE0"' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
