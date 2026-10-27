-- https://www3.hhu.de/stups/handbook/rodin/current/html/context.html#extendind_a_context
return {
  open = 'c2.mch',
  files = {
    ['a.mch'] = [[
context a
sets S
end
]],
    ['b.mch'] = [[
context b
sets S
end
]],
    ['c2.mch'] = [[
context c2 extends a b
end
]],
  },
  expect = { "c2.mch:1: 'S' is already declared" },
}
