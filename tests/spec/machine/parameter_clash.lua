-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#parameters
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
  end
  event set
    any n
    where
      @grd1 n ∈ ℕ
    then
      @act1 n ≔ n
  end
end
]],
  },
  expect = { "m0.mch:11: 'n' is already declared" },
}
