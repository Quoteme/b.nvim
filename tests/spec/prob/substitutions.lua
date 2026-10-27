-- https://prob.hhu.de/w/index.php?title=Summary_of_B_Syntax#Statements_(aka_Substitutions)
return {
  files = {
    ['M.mch'] = [[
MACHINE M
VARIABLES x, y
INVARIANT x : NATURAL & y : NATURAL
INITIALISATION x, y := 0, 0
OPERATIONS
  inc = PRE x < 10 THEN x := x + 1 END;
  choose = ANY v WHERE v : 0..3 THEN y := v END;
  pick = y :: 0..3;
  such = x : (x : 0..5);
  cond = IF x > 2 THEN x := 0 ELSIF x = 1 THEN x := 2 ELSE skip END;
  sel = SELECT x = 0 THEN y := 1 WHEN x = 1 THEN y := 2 ELSE skip END;
  par = BEGIN x := 1 || y := 2 END;
  loc = VAR t IN t := x; y := t END;
  r <-- get = r := x;
  cas = CASE x OF EITHER 0 THEN y := 1 OR 1 THEN y := 2 ELSE skip END END;
  loop = VAR i IN i := 0; WHILE i < 3 DO i := i + 1 INVARIANT i : 0..3 VARIANT 3 - i END END
END
]],
  },
  expect = {},
}
