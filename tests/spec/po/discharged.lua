-- https://www3.hhu.de/stups/handbook/rodin/current/html/generated_proof_obligations.html
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ 0 ‥ 10
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc
    when
      @grd1 n < 10
    then
      @act1 n ≔ n + 1
  end
end
]],
  },
  expect = {  },
}
