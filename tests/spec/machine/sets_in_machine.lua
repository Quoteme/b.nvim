-- https://wiki.event-b.org/index.php/TextEditor_EBNF
return {
  files = {
    ['m0.mch'] = [[
machine m0
sets S
end
]],
  },
  expect = { "m0.mch:2: sets, constants and axioms belong in a context" },
  syntax_error = true,
}
