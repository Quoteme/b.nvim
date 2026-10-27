-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#actions
return {
  open = 'm0.mch',
  files = {
    ['c0.mch'] = [[
context c0
constants k
axioms
  @axm1 k ∈ ℕ
end
]],
    ['m0.mch'] = [[
machine m0 sees c0
events
  event INITIALISATION
    then
      @act1 k ≔ 0
  end
end
]],
  },
  expect = { "m0.mch:5: 'k' is not a variable" },
}
