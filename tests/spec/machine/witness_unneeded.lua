-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#witness
return {
  open = 'm1.mch',
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
  end
end
]],
    ['m1.mch'] = [[
machine m1 refines m0
variables n
events
  event INITIALISATION
    with
      @q q = 0
    then
      @act1 n ≔ 0
  end
end
]],
  },
  expect = { "m1.mch:6: Witness 'q' is not an abstract parameter or disappearing variable" },
}
