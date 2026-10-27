-- https://www3.hhu.de/stups/handbook/rodin/current/html/well_definedness_proof_obligations.html#well_definedness_of_guards
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℤ
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event div
    any k
    where
      @grd1 10 ÷ k = n
  end
end
]],
  },
  expect = { "m0.mch:13: div/grd1/WD" },
}
