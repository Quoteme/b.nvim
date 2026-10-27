-- https://prob.hhu.de/w/index.php?title=Consistency_Checking
return {
  action = 'prob.modelCheck',
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ≤ 1
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  expect = { "m0.mch:10: inc/inv1/INV", "m0.mch:4: Invariant 'inv1' violated" },
}
