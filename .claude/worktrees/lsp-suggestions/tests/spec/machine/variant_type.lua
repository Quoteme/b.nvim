-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#termination
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables b
invariants
  @inv1 b ∈ BOOL
variant b
events
  event INITIALISATION
    then
      @act1 b ≔ TRUE
  end
end
]],
  },
  expect = { "m0.mch:5: Variant must be an integer or a set" },
}
