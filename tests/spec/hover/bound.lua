-- https://www3.hhu.de/stups/handbook/rodin/current/html/predicates.html#quantified_predicates
return {
  files = {
    ['c0.mch'] = [[
context c0
sets S
axioms
  @axm1 ∀x·x ∈ S ⇒ x = x
end
]],
  },
  hover = { 4, 10 },
  shows = { '**bound variable** `x ∈ S`', 'In `axm1`' },
}
