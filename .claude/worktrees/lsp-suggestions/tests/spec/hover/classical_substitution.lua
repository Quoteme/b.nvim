-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Statements_(aka_Substitutions)
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
  hover = { 7, 19 },
  shows = { '```b\nPRE P THEN G END\n```', 'inc = PRE count < 10 THEN count := count + 1 END' },
}
