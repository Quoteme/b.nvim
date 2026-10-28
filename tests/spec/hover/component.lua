-- https://www3.hhu.de/stups/handbook/rodin/current/html/machine.html#seeing_a_context
return {
  open = 'm0.mch',
  files = {
    ['c0.mch'] = [[
context c0
sets S
end
]],
    ['m0.mch'] = [[
machine m0 sees c0
end
]],
  },
  hover = { 1, 17 },
  shows = { 'context c0\n  sets S\nend', 'In `c0.mch`' },
}
