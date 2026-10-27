-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#extending_events
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
  event add
    any k
    where
      @grd1 k ∈ ℕ
    then
      @act1 n ≔ n + k
  end
end
]],
    ['m1.mch'] = [[
machine m1 refines m0
variables n m
invariants
  @inv1 m ∈ ℕ
events
  event INITIALISATION extends INITIALISATION
    then
      @act2 m ≔ 0
  end
  event add extends add
    then
      @act2 m ≔ k
  end
end
]],
  },
  expect = {},
}
