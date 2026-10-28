-- https://prob.hhu.de/w/index.php?title=Tutorial_Rodin_First_Step#Starting_ProB
return {
  files = {
    ['m0.mch'] = [[
machine m0
variables n
invariants
  @inv1 n ∈ 0 ‥ 3
events
  event INITIALISATION
    then
      @act1 n ≔ 0
  end
  event inc
    when
      @grd1 n < 3
    then
      @act1 n ≔ n + 1
  end
  event add
    any k
    where
      @grd1 k ∈ 1 ‥ 2
      @grd2 n + k ≤ 3
    then
      @act1 n ≔ n + k
  end
end
]],
  },
  steps = { 'INITIALISATION' },
  enabled = { 'add: k = 1', 'add: k = 2', 'inc' },
}
