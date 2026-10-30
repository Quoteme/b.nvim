-- https://prob.hhu.de/w/index.php?title=Animation#Animating_the_B_machine
return {
  files = {
    ['Counter.mch'] = [[
MACHINE Counter
VARIABLES n
INVARIANT n : 0..3
INITIALISATION n := 0
OPERATIONS
  inc = PRE n < 3 THEN n := n + 1 END;
  set(v) = PRE v : 0..3 THEN n := v END
END
]],
  },
  steps = { 'INITIALISATION', 'inc', { with = { 'set', 'v = 3' } } },
  variables = { n = '3' },
  history = { 'INITIALISATION', 'inc', 'set(3)' },
}
