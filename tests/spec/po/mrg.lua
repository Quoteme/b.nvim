-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#merging_events
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
  event low
    when
      @grd1 n < 3
    then
      @act1 n ≔ 0
  end
  event high
    when
      @grd1 n > 7
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
    then
      @act1 n ≔ 0
  end
  event step refines low high
    then
      @act1 n ≔ 0
  end
end
]],
  },
  expect = { "m1.mch:8: step/MRG" },
}
