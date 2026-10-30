-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#seeing_a_context
return {
  open = 'm0.mch',
  files = {
    ['c0.mch'] = [[
context c0
constants limit
axioms
  @axm1 limit ∈ ℕ
end
]],
    ['m0.mch'] = [[
machine m0 sees c0
variables n
invariants
  @inv1 n ∈ 0 ‥ limit
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
end
]],
  },
  expect = {},
}
