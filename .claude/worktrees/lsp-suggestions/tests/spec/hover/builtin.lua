-- https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#partition
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
  hover = { 7, 10 },
  shows = { '```eventb\npartition(S, A, B, …)\n```', '**Partitions of a set**', 'partition(1 ‥ 4, {1, 2}, {3, 4})', 'https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#partition' },
}
