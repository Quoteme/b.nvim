-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#action_simulation
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
  event inc
    when
      @grd1 n < 5
    then
      @act1 n ≔ n + 1
  end
end
]],
    ['m1.mch'] = [[
machine m1 refines m0
variables n
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc refines inc
    when
      @grd1 n < 5
    then
      @act1 n ≔ n + 2
  end
end
]],
  },
  expect = { "m1.mch:8: inc/act1/SIM" },
}
