-- https://prob.hhu.de/w/index.php?title=Graphical_Visualization#The_Graphical_Animation_Model
-- The 8-puzzle pattern, three by one: image 0 for empty squares overridden by
-- the board; an image is shown by its name as text.
return {
  files = {
    ['Slide.mch'] = [[
MACHINE Slide
DEFINITIONS
  ANIMATION_IMG0 == "images/sm_empty_box.gif";
  ANIMATION_IMG1 == "images/sm_1.gif";
  ANIMATION_FUNCTION == ( {r,c,i|r:1..1 & c:1..3 & i=0} <+ board )
VARIABLES board
INVARIANT board : (1..1) * (1..3) +-> 0..1
INITIALISATION board := {(1|->1)|->1}
OPERATIONS
  right = PRE (1|->1)|->1 : board THEN board := {(1|->2)|->1} END
END
]],
  },
  steps = { 'INITIALISATION', 'right' },
  graphics = { 'sm_empty_box sm_1 sm_empty_box' },
  images = true,
}
