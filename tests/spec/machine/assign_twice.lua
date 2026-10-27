-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#actions
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    then
      @act1 n ≔ 0
      @act2 n ≔ 1
  end
end
]],
  },
  expect = { "m0.mch:9: 'n' is assigned in more than one action" },
}
