-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#initialization
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
  end
end
]],
  },
  expect = { "m0.mch:6: Variable 'n' is not initialised", "m0.mch:6: INITIALISATION/inv1/INV" },
}
