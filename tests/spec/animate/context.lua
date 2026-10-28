-- https://prob.hhu.de/w/index.php?title=Tutorial_Rodin_First_Step#Starting_ProB
return {
  files = {
    ['c0.mch'] = [[
context c0
sets
  Personen
constants
  Roberta
  Theresa
axioms
  @axm1 partition(Personen, {Roberta}, {Theresa})
end
]],
  },
  steps = { 'SETUP_CONSTANTS' },
  constants = { Roberta = 'Roberta', Theresa = 'Theresa' },
  invariants = { axm1 = true },
  deadlock = false,
  history = { 'SETUP_CONSTANTS' },
}
