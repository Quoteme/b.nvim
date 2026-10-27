-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#a0000000398
return {
  files = {
    ['c0.mch'] = [[
context c0
sets S T
constants r f g h i j
axioms
  @axm1 r ∈ S ↔ T ∧ f ∈ S → T ∧ g ∈ S ⇸ T
  @axm2 h ∈ S ↣ T ∧ i ∈ S ↠ T ∧ j ∈ S ⤖ T
  @axm3 r ∈ S  T ∧ r ∈ S  T ∧ r ∈ S  T
end
]],
  },
  expect = {},
}
