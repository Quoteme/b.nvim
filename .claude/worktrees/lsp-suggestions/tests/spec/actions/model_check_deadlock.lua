-- https://prob.hhu.de/w/index.php?title=Consistency_Checking
return {
  action = 'prob.modelCheck',
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ 0 ‥ 2
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc
    when
      @grd1 n < 2
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  expect = { "m0.mch:1: Deadlock" },
}
