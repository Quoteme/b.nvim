-- https://www3.hhu.de/stups/handbook/rodin/current/html/assignments.html#nondeterministic_assignments
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
      @act1 n :∣ n' ∈ ℕ
  end
end
]],
  },
  hover = { 8, 18 },
  shows = { "**after-value**", "`n' ∈ ℤ`" },
}
