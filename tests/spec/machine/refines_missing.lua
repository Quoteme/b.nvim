-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#refinement_proof_obligations
return {
  open = 'm1.mch',
  files = {
    ['m0.mch'] = [[
machine m0
events
  event INITIALISATION
  end
end
]],
    ['m1.mch'] = [[
machine m1 refines m0
events
  event INITIALISATION
  end
  event go refines run
  end
end
]],
  },
  expect = { "m1.mch:5: The abstract machine has no event 'run'" },
}
