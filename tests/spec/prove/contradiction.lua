-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- ct proves the goal by contradiction: its negation becomes a hypothesis.
return {
  files = {
    ['c0.mch'] = [[
context c0
constants a
axioms
  @axm1 a ∈ ℤ
  theorem @thm1 ¬(a > 0 ∧ a < 0)
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'ct' },
  },
  goal = '⊥',
  hyps = { 'a>0', 'a<0' },
  remaining = 1,
  nodes = { 'ct goal' },
}
