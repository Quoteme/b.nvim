-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#carrier_sets
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
  hover = { 3, 3 },
  shows = { '**carrier set** `Personen`', 'https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#carrier_sets' },
}
