-- https://www3.hhu.de/stups/handbook/rodin/current/html/sets.html#set_comprehensions
return {
  files = {
    ['c0.mch'] = [[
context c0
constants evens squares
axioms
  @axm1 evens = {x · x ∈ ℕ ∧ x mod 2 = 0 ∣ x}
  @axm2 squares = {x · x ∈ 1 ‥ 5 ∣ x ∗ x}
  @axm3 evens ∩ squares = {x ∣ x ∈ squares ∧ x mod 2 = 0}
end
]],
  },
  expect = {},
}
