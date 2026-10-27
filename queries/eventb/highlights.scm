; Identifiers

(identifier) @variable

(machine
  name: (identifier) @module)

(context
  name: (identifier) @module)

(refines_clause
  (identifier) @module)

(sees_clause
  (identifier) @module)

(extends_clause
  (identifier) @module)

(variables_clause
  (identifier) @variable)

(carrier_set
  (identifier) @type)

(constant
  (identifier) @constant)

(event
  name: (identifier) @function)

(event
  refines: (identifier) @function)

(event
  extends: (identifier) @function)

(parameter
  (identifier) @variable.parameter)

(call
  function: (identifier) @function.call)

(label) @label

; Builtins and literals

(builtin_function) @function.builtin

(builtin_set) @type.builtin

(builtin_constant) @constant.builtin

(boolean) @boolean

(integer) @number

(empty_set) @constant.builtin

(comment) @comment @spell

; Keywords

[
  "machine"
  "context"
  "end"
] @keyword.type

[
  "refines"
  "sees"
  "extends"
  "variables"
  "invariants"
  "variant"
  "events"
  "sets"
  "constants"
  "axioms"
  "theorem"
] @keyword

[
  "event"
  "ordinary"
  "convergent"
  "anticipated"
] @keyword.function

[
  "any"
  "where"
  "when"
  "with"
  "then"
  "begin"
] @keyword

(quantified_predicate
  quantifier: _ @keyword.operator)

(quantified_expression
  quantifier: _ @keyword.operator)

; Operators and punctuation

(binary_formula
  operator: _ @operator)

(unary_formula
  operator: _ @operator)

(inverse
  [
    "∼"
    "~"
  ] @operator)

[
  "≔"
  ":="
  ":∈"
  "::"
  ":∣"
  ":|"
  "∣"
  "|"
] @operator

[
  "·"
  "."
  ","
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket
