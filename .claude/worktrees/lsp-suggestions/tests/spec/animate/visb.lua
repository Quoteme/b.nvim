-- https://prob.hhu.de/w/index.php?title=VisB
-- VISB_JSON_FILE names the VisB file; its items set SVG attributes from
-- B expressions, shown for the current state.
return {
  files = {
    ['Lamp.mch'] = [[
MACHINE Lamp
DEFINITIONS
  VISB_JSON_FILE == "lamp.json"
VARIABLES on
INVARIANT on : BOOL
INITIALISATION on := FALSE
OPERATIONS
  switch = on := bool(on = FALSE)
END
]],
    ['lamp.json'] = [[
{
  "svg": "lamp.svg",
  "items": [
    { "id": "lamp", "attr": "fill", "value": "IF on = TRUE THEN \"yellow\" ELSE \"gray\" END" }
  ]
}
]],
    ['lamp.svg'] = [[
<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100">
  <circle id="lamp" cx="50" cy="50" r="40" fill="white"/>
</svg>
]],
  },
  open = 'Lamp.mch',
  steps = { 'INITIALISATION', 'switch' },
  visb = true,
  visualize = {
    { 'visb', nil, {}, contains = 'attr: "fill", val: "yellow"' },
  },
}
