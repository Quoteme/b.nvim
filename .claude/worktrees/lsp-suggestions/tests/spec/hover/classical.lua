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
  shows = { '```b\nINVARIANT P\n```', 'Logical predicate', '**Example**', 'https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Machine_sections' },
}
