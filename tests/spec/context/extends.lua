-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#extendind_a_context
return {
  open = 'c1.mch',
  files = {
    ['c0.mch'] = [[
context c0
sets S
end
]],
    ['c1.mch'] = [[
context c1 extends c0
constants s
axioms
  @axm1 s ∈ S
end
]],
  },
  expect = {},
}
