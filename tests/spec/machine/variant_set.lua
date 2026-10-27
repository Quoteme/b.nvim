-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#set_variant
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables s
invariants
  @inv1 s ⊆ 1 ‥ 10
variant s
events
  event INITIALISATION
    then
      @act1 s ≔ 1 ‥ 10
  end
  convergent event take
    any x
    where
      @grd1 x ∈ s
    then
      @act1 s ≔ s ∖ {x}
  end
end
]],
  },
  expect = {},
}
