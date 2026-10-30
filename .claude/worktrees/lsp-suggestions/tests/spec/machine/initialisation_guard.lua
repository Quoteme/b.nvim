-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#initialization
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    where
      @grd1 ⊤
    then
      @act1 n ≔ 0
  end
end
]],
  },
  expect = { "m0.mch:8: INITIALISATION must not have guards" },
}
