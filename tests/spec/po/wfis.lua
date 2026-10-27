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
variables n
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event add refines add
    with
      @k k ∈ ℕ ∧ k < 0
    then
      @act1 n ≔ n
  end
end
]],
  },
  expect = { "m1.mch:10: add/k/WFIS" },
}
