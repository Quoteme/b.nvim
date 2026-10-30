-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Machine_sections
return {
  files = {
    ['M.mch'] = [[
MACHINE M
SETS COL = {red, green}
VARIABLES n
INVARIANT n : NATURAL
INITIALISATION n := 0
OPERATIONS
  r <-- step(k) = PRE k : 1..3 THEN n := n + k ; r := {n} \/ {} END
END
]],
  },
  complete = { 4, 'INVARIANT n : NATURAL & n /= gre' },
  offers = { 'green' },
}
