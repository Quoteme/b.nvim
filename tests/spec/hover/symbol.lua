-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#membership
return {
  files = {
    ['c0.mch'] = [[
context c0
sets
  Personen
constants
  Roberta
axioms
  @axm1 partition(Personen, {Roberta})
  @axm2 card(Personen) ∈ ℕ
end
]],
  },
  hover = { 8, 24 },
  shows = { '**set membership**', 'Checks if an expression E denotes an element of a set S.', 'ASCII: `:`', 'WD: L(E∈ S) ≙L(E) ∧ L(S)', 'https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#membership' },
}
