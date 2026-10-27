-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#termination
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
      @act1 n ≔ 10
  end
  convergent event dec
    when
      @grd1 n > 0
    then
      @act1 n ≔ n − 1
  end
end
]],
  },
  expect = { "m0.mch:10: Convergent event 'dec' requires a variant" },
}
