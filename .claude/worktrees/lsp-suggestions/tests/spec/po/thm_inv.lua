-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#variables_and_invariants
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
  theorem @thm1 n > 0
events
  event INITIALISATION
    then
      @act1 n ≔ 1
  end
end
]],
  },
  expect = { "m0.mch:5: thm1/THM" },
}
