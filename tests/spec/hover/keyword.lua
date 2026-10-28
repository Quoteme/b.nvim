-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#constants_and_axioms
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
  hover = { 4, 3 },
  shows = { '**constants**', 'https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#constants_and_axioms' },
}
