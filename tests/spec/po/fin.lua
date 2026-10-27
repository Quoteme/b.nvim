-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#set_variant
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables s
invariants
  @inv1 s ⊆ ℕ
variant s
events
  event INITIALISATION
    then
      @act1 s ≔ ℕ
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
  action = 'prob.showPOs',
  expect = {},
  quickfix = { "m0.mch:5: FIN: undischarged" },
}
