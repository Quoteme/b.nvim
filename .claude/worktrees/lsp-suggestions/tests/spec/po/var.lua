-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#numeric_variant
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
variant n
events
  event INITIALISATION
    then
      @act1 n ≔ 10
  end
  convergent event inc
    when
      @grd1 n < 20
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  expect = { "m0.mch:11: inc/VAR" },
}
