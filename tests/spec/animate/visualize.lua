-- https://prob.hhu.de/w/index.php?title=Graphical_Viewer
-- ProB Tcl/Tk's Visualize menu: graphs rendered by Graphviz, and tables.
return {
  files = {
    ['Counter.mch'] = [[
MACHINE Counter
VARIABLES n
INVARIANT n : 0..2
INITIALISATION n := 0
OPERATIONS
  inc = PRE n < 2 THEN n := n + 1 END
END
]],
  },
  steps = { 'INITIALISATION', 'inc' },
  visualize = {
    { 'dot', 'state_space', {}, contains = '<svg' },
    { 'dot', 'expr_as_graph', { '{n |-> 2}' }, contains = '<svg' },
    { 'table', 'expr_as_table', { '{1 |-> 2, 3 |-> 4}' }, header = { 'prj1', 'prj2' }, rows = { { '1', '2' }, { '3', '4' } } },
  },
}
