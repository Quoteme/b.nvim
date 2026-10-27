-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#function_application
return {
  files = {
    ['c0.mch'] = [[
context c0
constants f
axioms
  @axm1 f ∈ ℕ → ℕ
  @axm2 ∀n·n ∈ ℕ ⇒ f(n) = n + 1
end
]],
  },
  expect = {},
}
