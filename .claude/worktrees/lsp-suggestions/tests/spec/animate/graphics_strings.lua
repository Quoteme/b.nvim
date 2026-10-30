-- https://prob.hhu.de/w/index.php?title=Graphical_Visualization#Scheduler
-- ANIMATION_STRx instead of images, a default function under the current
-- one, and the pretty-printed value where neither is defined.
return {
  files = {
    ['Sched.mch'] = [[
MACHINE Sched
SETS PID = {p1, p2}
DEFINITIONS
  ANIMATION_STR4 == "--";
  ANIMATION_STR5 == "waiting";
  ANIMATION_STR6 == "active";
  ANIMATION_FUNCTION_DEFAULT == ( {1|->0|->5, 2|->0|->6} \/ {r,c,img|r:1..2 & img=4 & c:1..2} );
  ANIMATION_FUNCTION == ( {r,c,i| r=1 & c:1..2 & i=c & c:waiting} \/ {r,c,i| r=2 & c:1..2 & i=c & c:active} )
VARIABLES waiting, active
INVARIANT waiting <: 1..2 & active <: 1..2
INITIALISATION waiting := {1, 2} || active := {}
OPERATIONS
  run = waiting := {2} || active := {1}
END
]],
  },
  steps = { 'INITIALISATION', 'run' },
  graphics = { 'waiting -- 2', 'active 1 --' },
  images = false,
}
