-- https://www3.hhu.de/stups/handbook/rodin/current/html/arithmetic.html#arithmetic_operations
return {
  files = {
    ['c0.mch'] = [[
context c0
constants n
axioms
  @axm1 n = 7
  @axm2 n + 1 − 2 ∗ 3 ÷ 4 = 7 ∧ n mod 2 = 1 ∧ 2 ^ 3 = 8 ∧ −n < 0 ∧ succ(n) = pred(n) + 2
end
]],
  },
  expect = {},
}
