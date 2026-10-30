-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Strings
return {
  files = {
    ['M.mch'] = [[
MACHINE M
PROPERTIES
  "ab" : STRING & size("ab") = 2 & "a" ^ "b" = "ab"
END
]],
  },
  expect = {},
}
