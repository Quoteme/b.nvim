-- https://www3.hhu.de/stups/handbook/rodin/current/html/relations.html#relational_image
return {
  files = {
    ['c0.mch'] = [[
context c0
constants r
axioms
  @axm1 r = {1 ↦ 2, 3 ↦ 4}
  @axm2 r[{1}] = {2}
end
]],
  },
  expect = {},
}
