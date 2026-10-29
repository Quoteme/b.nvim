-- A proof made by Rodin, from the context "c" and its proof file c.bpr in Rodin's own
-- tests (org.eventb.core.tests/projects/Small, https://github.com/systerel/RodinCore,
-- EPL-1.0). Rodin's proof obligation generator now merges the repeated conjunct of
-- axm2/WD that the proof's first step, a simplification, removed; the proof is given
-- here from its second step on. Its rules are replayed as Rodin replays them. Pruning
-- and undoing saves the proof again, written by us, and saving the model replays that.
return {
  open = 'c.mch',
  files = {
    ['c.mch'] = [[
context c
constants f
axioms
  @axm1 f ∈ ℤ → ℤ
  @axm2 f(0) = f(1)
end
]],
    ['c.bpr'] = [[
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<org.eventb.core.prFile version="1">
<org.eventb.core.prProof name="axm2/WD" org.eventb.core.confidence="1000" org.eventb.core.prFresh="" org.eventb.core.prGoal="p2" org.eventb.core.prHyps="p1" org.eventb.core.psManual="true">
<org.eventb.core.prRule name="org.eventb.core.seqprover.conj" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="∧ goal" org.eventb.core.prGoal="p2" org.eventb.core.prHyps="">
<org.eventb.core.prAnte name="0" org.eventb.core.prGoal="p3">
<org.eventb.core.prRule name="org.eventb.core.seqprover.totalDom:2" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="total function dom substitution in goal" org.eventb.core.prGoal="p3" org.eventb.core.prHyps="p1">
<org.eventb.core.prAnte name="0" org.eventb.core.prGoal="p4">
<org.eventb.core.prRule name="org.eventb.core.seqprover.typeRewrites:0" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="type rewrites" org.eventb.core.prGoal="p4" org.eventb.core.prHyps="">
<org.eventb.core.prAnte name="0" org.eventb.core.prGoal="p5">
<org.eventb.core.prRule name="org.eventb.core.seqprover.trueGoal" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="⊤ goal" org.eventb.core.prGoal="p5" org.eventb.core.prHyps=""/>
</org.eventb.core.prAnte>
</org.eventb.core.prRule>
</org.eventb.core.prAnte>
<org.eventb.core.prString name=".pos" org.eventb.core.prSValue="1"/>
<org.eventb.core.prExprRef name=".subst" org.eventb.core.prRef="e0"/>
</org.eventb.core.prRule>
</org.eventb.core.prAnte>
<org.eventb.core.prAnte name="1" org.eventb.core.prGoal="p6">
<org.eventb.core.prRule name="org.eventb.core.seqprover.isFunGoal" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="functional goal" org.eventb.core.prGoal="p6" org.eventb.core.prHyps="p1"/>
</org.eventb.core.prAnte>
<org.eventb.core.prAnte name="2" org.eventb.core.prGoal="p7">
<org.eventb.core.prRule name="org.eventb.core.seqprover.totalDom:2" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="total function dom substitution in goal" org.eventb.core.prGoal="p7" org.eventb.core.prHyps="p1">
<org.eventb.core.prAnte name="0" org.eventb.core.prGoal="p8">
<org.eventb.core.prRule name="org.eventb.core.seqprover.typeRewrites:0" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="type rewrites" org.eventb.core.prGoal="p8" org.eventb.core.prHyps="">
<org.eventb.core.prAnte name="0" org.eventb.core.prGoal="p5">
<org.eventb.core.prRule name="org.eventb.core.seqprover.trueGoal" org.eventb.core.confidence="1000" org.eventb.core.prDisplay="⊤ goal" org.eventb.core.prGoal="p5" org.eventb.core.prHyps=""/>
</org.eventb.core.prAnte>
</org.eventb.core.prRule>
</org.eventb.core.prAnte>
<org.eventb.core.prString name=".pos" org.eventb.core.prSValue="1"/>
<org.eventb.core.prExprRef name=".subst" org.eventb.core.prRef="e0"/>
</org.eventb.core.prRule>
</org.eventb.core.prAnte>
</org.eventb.core.prRule>
<org.eventb.core.prIdent name="f" org.eventb.core.type="ℙ(ℤ×ℤ)"/>
<org.eventb.core.prPred name="p5" org.eventb.core.predicate="⊤"/>
<org.eventb.core.prPred name="p2" org.eventb.core.predicate="0∈dom(f)∧f∈ℤ ⇸ ℤ∧1∈dom(f)"/>
<org.eventb.core.prPred name="p4" org.eventb.core.predicate="0∈ℤ"/>
<org.eventb.core.prPred name="p3" org.eventb.core.predicate="0∈dom(f)"/>
<org.eventb.core.prPred name="p6" org.eventb.core.predicate="f∈ℤ ⇸ ℤ"/>
<org.eventb.core.prPred name="p8" org.eventb.core.predicate="1∈ℤ"/>
<org.eventb.core.prPred name="p1" org.eventb.core.predicate="f∈ℤ → ℤ"/>
<org.eventb.core.prPred name="p7" org.eventb.core.predicate="1∈dom(f)"/>
<org.eventb.core.prExpr name="e0" org.eventb.core.expression="ℤ"/>
</org.eventb.core.prProof>
</org.eventb.core.prFile>
]],
  },
  prove = 'axm2/WD',
  tactics = {
    { action = 'prune', node = '0' },
    { action = 'undo' },
  },
  status = 'proved',
  remaining = 0,
  nodes = { '∧ goal', 'total function dom substitution in goal', 'type rewrites', 'functional goal', '⊤ goal' },
  bpr = { 'org.eventb.core.prRID="org.eventb.core.seqprover.totalDom:2"', 'org.eventb.core.prString name=".pos" org.eventb.core.prSValue="1"' },
  after = { status = 'proved', remaining = 0, nodes = { 'functional goal' }, expect = {} },
}
