-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- Instantiating an ∃ goal and a ∀ hypothesis, then modus ponens: ProB cannot
-- discharge the obligation on its own, as f is infinite, but proves what is left.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants f
axioms
  @axm1 f ∈ ℕ → ℕ
  @axm2 ∀x·x ∈ ℕ ⇒ f(x) > x
  theorem @thm1 ∃y·f(y) > 0
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'exI', input = '0' },
    { 'allD', hyp = '∀x·x∈ℕ⇒f(x)>x', input = '0' },
    { 'impE', hyp = '0∈ℕ⇒f(0)>0' },
    { action = 'prob' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { '∃ goal (inst 0)', '∀ hyp (inst 0)', '⇒ hyp mp (0∈ℕ⇒f(0)>0)', 'hyp' },
  bpr = { 'org.eventb.core.prExprRef name=".exprs"', 'org.eventb.core.prRID="org.eventb.core.seqprover.impE:2"' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
