-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#parameters
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ ℕ
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event add
    any k
    where
      @grd1 k ∈ 1 ‥ 3
    then
      @act1 n ≔ n + k
  end
end
]],
  },
  hover = { 13, 13 },
  shows = { '**parameter** `k ∈ ℤ`', 'Of event `add`' },
}
