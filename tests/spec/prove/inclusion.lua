-- https://www3.hhu.de/stups/handbook/rodin/current/html/proving_perspective.html#proof_control
-- Removing ⊆, freeing x and rewriting with an equality: the goal is a hypothesis.
return {
  files = {
    ['c0.mch'] = [[
context c0
sets S
constants a b
axioms
  @axm1 a ⊆ S
  @axm2 b = a
  theorem @thm1 a ⊆ b
end
]],
  },
  prove = 'thm1/THM',
  tactics = {
    { 'ri' },
    { 'allI' },
    { 'impI' },
    { 'eh', hyp = 'b=a' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { 'remove ⊆ in goal', '∀ goal (frees x)', '⇒ goal', 'eh with b=a', 'hyp' },
  bpr = { 'org.eventb.core.prSets="S"', 'org.eventb.core.type="ℙ(S)"' },
  after = { status = 'proved', remaining = 0, expect = {} },
}
