-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Machine_sections
return {
  files = {
    ['M.mch'] = [[
MACHINE M
VARIABLES x
INVARIANT x : NATURAL
INITIALISATION x := 0
END
]],
  },
  hover = { 3, 2 },
  shows = { '`INVARIANT P` — logical predicate', 'https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Machine_sections' },
}
