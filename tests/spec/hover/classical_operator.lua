-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Sets
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
  hover = { 7, 59 },
  shows = { '```b\nS\\/T\n```', 'Set union', '{1, 2} \\/ {2, 3} = {1, 2, 3}', 'https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Sets' },
}
