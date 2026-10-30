-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Sequences
return {
  files = {
    ['M.mch'] = [==[
MACHINE M
CONSTANTS s
PROPERTIES
  s = [1, 2, 3] & s : seq(NATURAL) & size(s) = 3 & first(s) = 1 & last(s) = 3 & front(s) = [1, 2]
  & tail(s) = [2, 3] & rev(s) = [3, 2, 1] & s ^ [4] = [1, 2, 3, 4] & 0 -> s = [0, 1, 2, 3] & s <- 4 = [1, 2, 3, 4]
  & s /|\ 1 = [1] & s \|/ 1 = [2, 3] & conc([[1], [2]]) = [1, 2] & <> : iseq(NATURAL)
END
]==],
  },
  expect = {},
}
