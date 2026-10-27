-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Equality
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES 1 = TRUE
END
]],
  },
  expect = { "M.mch:2: Type mismatch" },
}
