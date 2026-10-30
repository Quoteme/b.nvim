-- https://wiki.event-b.org/index.php/Event-B_Mathematical_Language
return {
  files = {
    ['c0.mch'] = [[
context c0
constants f
axioms
  @axm1 f : NAT --> NAT & (!x.(x : NAT => f(x) >= 0))
  @axm2 {1 |-> 2} <+ {1 |-> 3} = {1 |-> 3} or not(1 /= 1)
end
]],
  },
  expect = {},
}
