; Identifiers

(identifier) @variable

(component
  name: (identifier) @module)

(machine_reference
  name: (identifier) @module)

(refines_clause
  (identifier) @module)

(promotes_clause
  (identifier) @function)

(set_declaration
  name: (identifier) @type)

(set_declaration
  element: (identifier) @constant)

(set_declaration
  definition: (identifier) @function.macro)

(constants_clause
  (identifier_list
    (identifier) @constant))

(definition
  name: (identifier) @function.macro)

(parameter_list
  (identifier) @variable.parameter)

(operation
  name: (identifier) @function)

(operation
  results: (identifier_list
    (identifier) @variable.parameter))

(rule_operation
  name: (identifier) @function)

(computation_operation
  name: (identifier) @function)

(function_operation
  name: (identifier) @function)

(function_operation
  results: (identifier_list
    (identifier) @variable.parameter))

(operation_call
  name: (identifier) @function.call)

(call
  function: (identifier) @function.call)

(record_field
  field: (identifier) @variable.member)

(record_entry
  field: (identifier) @variable.member)

(define_substitution
  name: (identifier) @variable)

(freetype
  name: (identifier) @type)

(freetype_constructor
  name: (identifier) @constructor)

(value_entry
  name: (identifier) @constant)

(primed_identifier
  "$0" @operator)

; Builtins and literals

(builtin_function) @function.builtin

(record
  kind: _ @function.builtin)

(builtin_set) @type.builtin

(builtin_constant) @constant.builtin

(boolean) @boolean

(integer) @number

(real) @number.float

(string) @string

(definition_file
  (string) @string.special.path)

[
  (empty_set)
  (empty_sequence)
] @constant.builtin

(skip) @keyword

(attribute_name) @attribute

(comment) @comment @spell

(pragma) @comment.documentation

; Keywords

[
  "MACHINE"
  "MODEL"
  "SYSTEM"
  "REFINEMENT"
  "IMPLEMENTATION"
  "RULES_MACHINE"
  "END"
] @keyword.type

[
  "REFINES"
  "DEFINITIONS"
  "CONSTRAINTS"
  "SEES"
  "USES"
  "INCLUDES"
  "EXTENDS"
  "IMPORTS"
  "REFERENCES"
  "PROMOTES"
  "SETS"
  "CONSTANTS"
  "CONCRETE_CONSTANTS"
  "ABSTRACT_CONSTANTS"
  "VISIBLE_CONSTANTS"
  "HIDDEN_CONSTANTS"
  "VARIABLES"
  "CONCRETE_VARIABLES"
  "ABSTRACT_VARIABLES"
  "VISIBLE_VARIABLES"
  "HIDDEN_VARIABLES"
  "PROPERTIES"
  "INVARIANT"
  "ASSERTIONS"
  "VALUES"
  "INITIALISATION"
  "INITIALIZATION"
  "OPERATIONS"
  "LOCAL_OPERATIONS"
  "EVENTS"
  "FREETYPES"
] @keyword

[
  "RULE"
  "COMPUTATION"
  "FUNCTION"
  "BODY"
] @keyword.function

[
  "BEGIN"
  "PRE"
  "ASSERT"
  "ANY"
  "WHERE"
  "VAR"
  "LET"
  "BE"
  "IN"
  "DEFINE"
  "TYPE"
  "VALUE"
  "DUMMY_VALUE"
  "RULE_FAIL"
  "EXPECT"
  "ON_SUCCESS"
  "UNCHECKED"
  "COUNTEREXAMPLE"
  "ERROR_TYPE"
] @keyword

[
  "IF"
  "THEN"
  "ELSIF"
  "ELSE"
  "SELECT"
  "WHEN"
  "CASE"
  "OF"
  "EITHER"
  "OR"
  "CHOICE"
] @keyword.conditional

[
  "WHILE"
  "DO"
  "VARIANT"
  "FOR"
  "RULE_FORALL"
] @keyword.repeat

(while_substitution
  "INVARIANT" @keyword.repeat)

(quantified_predicate
  quantifier: _ @keyword.operator)

(quantified_expression
  quantifier: _ @keyword.operator)

; Operators and punctuation

(binary_formula
  operator: _ @operator)

(unary_formula
  operator: _ @operator)

(composition
  operator: _ @operator)

(inverse
  [
    "~"
    "∼"
    "⁻¹"
  ] @operator)

[
  ":="
  "≔"
  "::"
  ":∈"
  "<--"
  "←"
  "⟵"
  "=="
  "||"
  "∥"
  "‖"
  "|"
  "∣"
] @operator

(operation
  "=" @operator)

(set_declaration
  "=" @operator)

(value_entry
  "=" @operator)

(freetype
  "=" @operator)

(becomes_such_that
  [
    ":"
    "∈"
  ] @operator)

(record_entry
  [
    ":"
    "∈"
  ] @punctuation.delimiter)

[
  "."
  "·"
  "•"
  "⋅"
  ","
  ";"
  "'"
] @punctuation.delimiter

[
  "("
  ")"
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket
