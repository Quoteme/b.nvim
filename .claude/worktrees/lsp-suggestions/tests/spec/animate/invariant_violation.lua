-- https://prob.hhu.de/w/index.php?title=Animation#Animating_the_B_machine
return {
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
  steps = { 'INITIALISATION', 'inc', 'inc' },
  invariants = { inv1 = false },
}
