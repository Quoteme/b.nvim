-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#witness
return {
  open = 'm1.mch',
  files = {
    ['m0.mch'] = [[
machine m0
variables a
invariants
  @inv1 a ∈ ℕ
events
  event INITIALISATION
    then
      @act1 a :∈ ℕ
  end
end
]],
    ['m1.mch'] = [[
machine m1 refines m0
variables b
invariants
  @inv1 b ∈ ℕ
events
  event INITIALISATION
    with
      @a' a' = b'
    then
      @act1 b ≔ 0
  end
end
]],
  },
  expect = {},
}
