-- https://prob.hhu.de/w/index.php?title=Tutorial_Rodin_First_Step#Starting_ProB
return {
  open = 'm0.mch',
  files = {
    ['c0.mch'] = [[
context c0
constants limit
axioms
  @axm1 limit ∈ {2, 4}
end
]],
    ['m0.mch'] = [[
machine m0 sees c0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    then
      @act1 n ≔ limit
  end
end
]],
  },
  steps = {},
  enabled = { 'SETUP_CONSTANTS: limit = 2', 'SETUP_CONSTANTS: limit = 4' },
}
