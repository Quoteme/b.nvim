-- https://www3.hhu.de/stups/handbook/rodin/current/html/typing.html
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 (∅ ⦂ ℙ(ℤ)) = ∅
  @axm2 ∃x ⦂ ℤ, y·x ≠ y
end
]],
  },
  expect = {},
}
