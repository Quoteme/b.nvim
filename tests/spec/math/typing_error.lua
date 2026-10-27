-- https://www3.hhu.de/stups/handbook/rodin/current/html/typing.html
return {
  files = {
    ['c0.mch'] = [[
context c0
axioms
  @axm1 ∅ = ∅
end
]],
  },
  expect = { "c0.mch:3: Variable has an unknown type", "c0.mch:3: Variable has an unknown type" },
}
