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
  shows = { '**Element of**', 'Typed as `:`', 'https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#membership' },
}
