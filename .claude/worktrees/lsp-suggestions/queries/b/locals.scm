; Scopes

[
  (component)
  (definition)
  (operation)
  (rule_operation)
  (computation_operation)
  (function_operation)
  (any_substitution)
  (var_substitution)
  (let_substitution)
  (let_formula)
  (for_substitution)
  (rule_forall_substitution)
  (rule_fail_substitution)
  (quantified_predicate)
  (quantified_expression)
  (set_comprehension)
] @local.scope

; Definitions

(component
  name: (identifier) @local.definition.namespace)

(definition
  name: (identifier) @local.definition.macro)

(set_declaration
  name: (identifier) @local.definition.type)

(set_declaration
  element: (identifier) @local.definition.constant)

(constants_clause
  (identifier_list
    (identifier) @local.definition.constant))

(variables_clause
  (identifier_list
    (identifier) @local.definition.var))

(parameter_list
  (identifier) @local.definition.parameter)

(operation
  name: (identifier) @local.definition.function)

(operation
  results: (identifier_list
    (identifier) @local.definition.parameter))

(rule_operation
  name: (identifier) @local.definition.function)

(computation_operation
  name: (identifier) @local.definition.function)

(function_operation
  name: (identifier) @local.definition.function)

(define_substitution
  name: (identifier) @local.definition.var)

(any_substitution
  (identifier_list
    (identifier) @local.definition.var))

(var_substitution
  (identifier_list
    (identifier) @local.definition.var))

(let_substitution
  (identifier_list
    (identifier) @local.definition.var))

(let_formula
  (identifier_list
    (identifier) @local.definition.var))

(for_substitution
  (identifier_list
    (identifier) @local.definition.var))

(rule_forall_substitution
  (identifier_list
    (identifier) @local.definition.var))

(rule_fail_substitution
  (identifier_list
    (identifier) @local.definition.var))

(quantified_predicate
  variables: (identifier_list
    (identifier) @local.definition.var))

(quantified_expression
  variables: (identifier_list
    (identifier) @local.definition.var))

; References

(identifier) @local.reference
