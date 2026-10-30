; Scopes

[
  (machine)
  (context)
  (event)
  (quantified_predicate)
  (quantified_expression)
  (set_comprehension)
] @local.scope

; Definitions

(machine
  name: (identifier) @local.definition.namespace)

(context
  name: (identifier) @local.definition.namespace)

(variables_clause
  (identifier) @local.definition.var)

(carrier_set
  (identifier) @local.definition.type)

(constant
  (identifier) @local.definition.constant)

(event
  name: (identifier) @local.definition.function)

(parameter
  (identifier) @local.definition.parameter)

(quantified_predicate
  variables: (identifier_list
    (identifier) @local.definition.var))

(set_comprehension
  variables: (identifier) @local.definition.var)

; References

(identifier) @local.reference
