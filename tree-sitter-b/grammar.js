/**
 * @file Classical B (B-Method) grammar for tree-sitter, as accepted by ProB.
 * @license EPL-2.0
 *
 * Structure and operator priorities follow ProB's BParser.scc and
 * RulesGrammar.java (hhu-stups/probparsers).
 *
 * ProB tells predicates and expressions apart with a pre-parser that knows
 * the kind of every DEFINITION. A context-free grammar cannot do that, so
 * both are parsed as one `_formula` using B's priorities: predicate
 * connectives bind weakest, then comparisons, then expression operators.
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const PREC = {
  composition: 20, // ; and || inside parentheses
  implies: 30,
  and_or: 40,
  equivalence: 60,
  comparison: 70,
  relation: 125,
  set_op: 160,
  interval: 170,
  additive: 180,
  multiplicative: 190,
  power: 200,
  unary: 210,
  inverse: 230,
  application: 231,
};

// ASCII and Unicode spellings of every operator.
const OP = {
  implies: ['=>', '⇒', '⟹'],
  and: ['&', '∧'],
  or: ['or', '∨'],
  equivalence: ['<=>', '⇔', '⟺'],
  comparison: [
    '=', '/=', '≠',
    ':', '∈', '/:', '∉', '∋', '∌',
    '<:', '⊆', '<<:', '⊂', '⊊', '/<:', '⊈', '/<<:', '⊄',
    '⊇', '⊃', '⊅', '⊋', '⊉',
    '<', '<=', '≤', '>', '>=', '≥',
  ],
  relation: [
    '<->', '↔', '+->', '⇸', '-->', '→', '>+>', '⤔', '>->', '↣',
    '+->>', '⤀', '-->>', '↠', '>+>>', '>->>', '⤖',
    '<<->', '<->>', '<<->>',
  ],
  set_op: [
    '<+', '\uE103', '⋖', '><', '⊗', '∘', '^', '⌒',
    '<|', '◁', '<<|', '⩤', '◀', '|>', '▷', '|>>', '⩥', '▶',
    '->', '⇾', '<-', '⇽', '\\/', '∪', '/\\', '∩',
    '/|\\', '↑', '\\|/', '↓', '|->', '↦',
  ],
  additive: ['+', '-', '−', '\\', '∖'],
  multiplicative: ['*', '∗', '×', '⨯', '/', '÷', 'mod'],
  power: ['**', '˄'],
};

const BUILTIN_FUNCTIONS = [
  'bool', 'card', 'floor', 'ceiling', 'real', 'closure', 'closure1', 'conc',
  'dom', 'first', 'fnc', 'front', 'id', 'inter', 'iseq', 'iseq1', 'iterate',
  'last', 'max', 'min', 'not', '¬', 'perm', 'prj1', 'prj2', 'ran', 'rel',
  'rev', 'seq', 'seq1', 'size', 'tail', 'union',
  'POW', 'ℙ', 'POW1', 'ℙ1', 'ℙ₁', 'FIN', 'FIN1', '@finite', '@partition',
];

const BUILTIN_SETS = [
  'NAT', 'NAT1', 'NATURAL', 'ℕ', 'NATURAL1', 'ℕ1', 'ℕ₁', 'INT', 'INTEGER', 'ℤ',
  'REAL', 'ℝ', 'FLOAT', 'BOOL', 'STRING',
];

const QUANTIFIED_EXPRESSIONS = ['%', 'λ', 'SIGMA', '∑', 'PI', '∏', 'UNION', '⋃', 'INTER', '⋂'];

const RULE_ATTRIBUTES = [
  'DEPENDS_ON_RULE', 'DEPENDS_ON_COMPUTATION', 'RULEID', 'ERROR_TYPES',
  'CLASSIFICATION', 'TAGS', 'REPLACES', 'ACTIVATION', 'PRECONDITION', 'POSTCONDITION',
];

/**
 * @param {RuleOrLiteral} separator
 * @param {RuleOrLiteral} rule
 */
function sepBy1(separator, rule) {
  return seq(rule, repeat(seq(separator, rule)));
}

/** @param {RuleOrLiteral} rule */
function commaSep1(rule) {
  return sepBy1(',', rule);
}

/** @param {string[]} spellings */
function op(spellings) {
  return choice(...spellings);
}

module.exports = grammar({
  name: 'b',

  extras: $ => [/\s/, $.comment, $.pragma],

  word: $ => $.identifier,

  conflicts: $ => [
    // An identifier or call may start an expression or an operation call.
    [$._formula, $.operation_call],
    [$._formula, $._assign_target],
    [$._formula, $._assign_target, $.operation_call],
    [$._assign_target, $.operation_call],
  ],

  rules: {
    source_file: $ => choice($.component, $.definitions_clause),

    // ------------------------------------------------------------------
    // Components and clauses

    component: $ => seq(
      field('kind', choice(
        'MACHINE', 'MODEL', 'SYSTEM', 'REFINEMENT', 'IMPLEMENTATION', 'RULES_MACHINE',
      )),
      field('name', $.identifier),
      optional(field('parameters', $.parameter_list)),
      repeat($._clause),
      'END',
    ),

    parameter_list: $ => seq('(', commaSep1($.identifier), ')'),

    _clause: $ => choice(
      $.refines_clause,
      $.definitions_clause,
      $.constraints_clause,
      $.machine_reference_clause,
      $.promotes_clause,
      $.sets_clause,
      $.constants_clause,
      $.variables_clause,
      $.properties_clause,
      $.invariant_clause,
      $.assertions_clause,
      $.values_clause,
      $.initialisation_clause,
      $.operations_clause,
      $.freetypes_clause,
    ),

    refines_clause: $ => seq('REFINES', $.identifier),

    definitions_clause: $ => seq(
      'DEFINITIONS',
      sepBy1(';', choice($.definition, $.definition_file)),
      optional(';'),
    ),

    definition: $ => seq(
      field('name', $.identifier),
      optional(field('parameters', $.parameter_list)),
      '==',
      field('body', choice($._formula, $._substitution_l3)),
    ),

    definition_file: $ => $.string,

    constraints_clause: $ => seq('CONSTRAINTS', $._formula),

    machine_reference_clause: $ => seq(
      choice('SEES', 'USES', 'INCLUDES', 'EXTENDS', 'IMPORTS', 'REFERENCES'),
      commaSep1($.machine_reference),
    ),

    machine_reference: $ => seq(
      field('name', $.identifier),
      optional(seq('(', commaSep1($._formula), ')')),
    ),

    promotes_clause: $ => seq('PROMOTES', commaSep1($.identifier)),

    sets_clause: $ => seq('SETS', sepBy1(';', $.set_declaration), optional(';')),

    set_declaration: $ => seq(
      field('name', $.identifier),
      optional(seq(
        '=',
        choice(
          seq('{', commaSep1(field('element', $.identifier)), '}'),
          field('definition', $.identifier),
        ),
      )),
    ),

    constants_clause: $ => seq(
      choice('CONSTANTS', 'CONCRETE_CONSTANTS', 'ABSTRACT_CONSTANTS', 'VISIBLE_CONSTANTS', 'HIDDEN_CONSTANTS'),
      $.identifier_list,
    ),

    variables_clause: $ => seq(
      choice('VARIABLES', 'CONCRETE_VARIABLES', 'ABSTRACT_VARIABLES', 'VISIBLE_VARIABLES', 'HIDDEN_VARIABLES'),
      $.identifier_list,
    ),

    properties_clause: $ => seq('PROPERTIES', $._formula),

    invariant_clause: $ => seq('INVARIANT', $._formula),

    assertions_clause: $ => seq('ASSERTIONS', sepBy1(';', $._formula), optional(';')),

    values_clause: $ => seq('VALUES', sepBy1(';', $.value_entry), optional(';')),

    value_entry: $ => seq(field('name', $.identifier), '=', field('value', $._formula)),

    initialisation_clause: $ => seq(choice('INITIALISATION', 'INITIALIZATION'), $._substitution),

    operations_clause: $ => seq(
      choice('OPERATIONS', 'LOCAL_OPERATIONS', 'EVENTS'),
      repeat(seq($._operation, optional(';'))),
    ),

    freetypes_clause: $ => seq('FREETYPES', sepBy1(';', $.freetype), optional(';')),

    freetype: $ => seq(
      field('name', $.identifier),
      optional(field('parameters', $.parameter_list)),
      '=',
      commaSep1($.freetype_constructor),
    ),

    freetype_constructor: $ => seq(
      field('name', $.identifier),
      optional(seq('(', $._formula_in_parentheses, ')')),
    ),

    // ------------------------------------------------------------------
    // Operations

    _operation: $ => choice($.operation, $.rule_operation, $.computation_operation, $.function_operation),

    operation: $ => seq(
      optional(seq(field('results', $.identifier_list), choice('<--', '←', '⟵'))),
      field('name', $.identifier),
      optional(field('parameters', $.parameter_list)),
      '=',
      field('body', $._substitution_l2),
    ),

    rule_operation: $ => seq(
      'RULE',
      field('name', $.identifier),
      repeat($.rule_attribute),
      'BODY',
      field('body', $._substitution),
      'END',
    ),

    computation_operation: $ => seq(
      'COMPUTATION',
      field('name', $.identifier),
      repeat($.rule_attribute),
      'BODY',
      field('body', $._substitution),
      'END',
    ),

    function_operation: $ => seq(
      'FUNCTION',
      field('results', $.identifier_list),
      choice('<--', '←', '⟵'),
      field('name', $.identifier),
      optional(field('parameters', $.parameter_list)),
      repeat($.rule_attribute),
      'BODY',
      field('body', $._substitution),
      'END',
    ),

    rule_attribute: $ => seq(
      field('name', alias(choice(...RULE_ATTRIBUTES), $.attribute_name)),
      commaSep1($._formula),
    ),

    // ------------------------------------------------------------------
    // Substitutions

    // All substitutions: `;` binds weaker than `||`.
    _substitution: $ => choice($.sequential_substitution, $._substitution_l2),

    sequential_substitution: $ => prec.left(seq(
      $._substitution_l2,
      repeat1(seq(';', $._substitution_l2)),
      optional(';'),
    )),

    _substitution_l2: $ => choice($.parallel_substitution, $._substitution_l3),

    parallel_substitution: $ => prec.left(seq(
      $._substitution_l3,
      repeat1(seq(choice('||', '∥', '‖'), $._substitution_l3)),
    )),

    _substitution_l3: $ => choice(
      $.block_substitution,
      $.skip,
      $.assignment,
      $.becomes_element_of,
      $.becomes_such_that,
      $.operation_call,
      $.precondition_substitution,
      $.assert_substitution,
      $.choice_substitution,
      $.if_substitution,
      $.select_substitution,
      $.case_substitution,
      $.any_substitution,
      $.var_substitution,
      $.let_substitution,
      $.while_substitution,
      $.for_substitution,
      $.rule_forall_substitution,
      $.rule_fail_substitution,
      $.define_substitution,
    ),

    block_substitution: $ => seq('BEGIN', $._substitution, 'END'),

    skip: _ => 'skip',

    _assign_target: $ => choice(
      $.identifier,
      alias($._assign_call, $.call),
      alias($._assign_field, $.record_field),
    ),

    _assign_call: $ => prec(PREC.application, seq(
      field('function', $._assign_target),
      '(', $.arguments, ')',
    )),

    _assign_field: $ => prec(PREC.application, seq(
      field('record', $._assign_target),
      "'",
      field('field', $.identifier),
    )),

    _assign_targets: $ => commaSep1($._assign_target),

    assignment: $ => seq(
      field('left', $._assign_targets),
      choice(':=', '≔'),
      field('right', commaSep1($._formula)),
    ),

    becomes_element_of: $ => seq(
      field('left', $._assign_targets),
      choice('::', ':∈'),
      field('right', $._formula),
    ),

    becomes_such_that: $ => seq(
      field('left', $._assign_targets),
      choice(':', '∈'),
      '(', field('predicate', $._formula), ')',
    ),

    operation_call: $ => prec.right(seq(
      optional(seq(field('results', $._assign_targets), choice('<--', '←', '⟵'))),
      field('name', $.identifier),
      optional(seq('(', optional($.arguments), ')')),
    )),

    precondition_substitution: $ => seq('PRE', $._formula, 'THEN', $._substitution, 'END'),

    assert_substitution: $ => seq('ASSERT', $._formula, 'THEN', $._substitution, 'END'),

    choice_substitution: $ => seq(
      'CHOICE', $._substitution,
      repeat(seq('OR', $._substitution)),
      'END',
    ),

    if_substitution: $ => seq(
      'IF', field('condition', $._formula),
      'THEN', field('consequence', $._substitution),
      repeat($.elsif_substitution),
      optional(seq('ELSE', field('alternative', $._substitution))),
      'END',
    ),

    elsif_substitution: $ => seq(
      'ELSIF', field('condition', $._formula),
      'THEN', field('consequence', $._substitution),
    ),

    select_substitution: $ => seq(
      'SELECT', field('condition', $._formula),
      'THEN', $._substitution,
      repeat(seq('WHEN', $._formula, 'THEN', $._substitution)),
      optional(seq('ELSE', $._substitution)),
      'END',
    ),

    case_substitution: $ => seq(
      'CASE', field('value', $._formula_in_parentheses), 'OF',
      'EITHER', commaSep1($._formula), 'THEN', $._substitution,
      repeat(seq('OR', commaSep1($._formula), 'THEN', $._substitution)),
      optional(seq('ELSE', $._substitution)),
      'END',
      'END',
    ),

    any_substitution: $ => seq(
      'ANY', $.identifier_list,
      'WHERE', $._formula,
      'THEN', $._substitution,
      'END',
    ),

    var_substitution: $ => seq('VAR', $.identifier_list, 'IN', $._substitution, 'END'),

    let_substitution: $ => seq(
      'LET', $.identifier_list,
      'BE', $._formula,
      'IN', $._substitution,
      'END',
    ),

    while_substitution: $ => seq(
      'WHILE', field('condition', $._formula),
      'DO', field('body', $._substitution),
      'INVARIANT', field('invariant', $._formula),
      'VARIANT', field('variant', $._formula_in_parentheses),
      'END',
    ),

    for_substitution: $ => seq(
      'FOR', $.identifier_list,
      'IN', $._formula_in_parentheses,
      'DO', $._substitution,
      'END',
    ),

    rule_forall_substitution: $ => seq(
      'RULE_FORALL', $.identifier_list,
      'WHERE', $._formula,
      'EXPECT', $._formula,
      optional(seq('ERROR_TYPE', $.integer)),
      optional(seq('ON_SUCCESS', $._formula)),
      optional(seq('UNCHECKED', $._formula)),
      'COUNTEREXAMPLE', $._formula,
      'END',
    ),

    rule_fail_substitution: $ => seq(
      'RULE_FAIL',
      optional($.identifier_list),
      optional(seq('WHEN', $._formula)),
      optional(seq('ERROR_TYPE', $.integer)),
      'COUNTEREXAMPLE', $._formula,
      'END',
    ),

    define_substitution: $ => seq(
      'DEFINE', field('name', $.identifier),
      optional(seq('TYPE', $._formula_in_parentheses)),
      optional(seq('DUMMY_VALUE', $._formula_in_parentheses)),
      'VALUE', $._formula_in_parentheses,
      'END',
    ),

    // ------------------------------------------------------------------
    // Predicates and expressions

    _formula: $ => choice(
      $.binary_formula,
      $.unary_formula,
      $.inverse,
      $.image,
      $.call,
      $.record_field,
      $.builtin_call,
      $.quantified_predicate,
      $.quantified_expression,
      $.set_comprehension,
      $.set_extension,
      $.empty_set,
      $.sequence_extension,
      $.empty_sequence,
      $.parenthesized_formula,
      $.tuple,
      $.record,
      $.if_formula,
      $.let_formula,
      $.identifier,
      $.primed_identifier,
      $.integer,
      $.real,
      $.string,
      $.boolean,
      $.builtin_set,
      $.builtin_constant,
    ),

    binary_formula: $ => choice(
      ...[
        [PREC.implies, OP.implies],
        [PREC.and_or, [...OP.and, ...OP.or]],
        [PREC.equivalence, OP.equivalence],
        [PREC.comparison, OP.comparison],
        [PREC.relation, OP.relation],
        [PREC.set_op, OP.set_op],
        [PREC.interval, ['..', '‥']],
        [PREC.additive, OP.additive],
        [PREC.multiplicative, OP.multiplicative],
      ].map(([precedence, operators]) => prec.left(/** @type {number} */ (precedence), seq(
        field('left', $._formula),
        field('operator', op(/** @type {string[]} */ (operators))),
        field('right', $._formula),
      ))),
      prec.right(PREC.power, seq(
        field('left', $._formula),
        field('operator', op(OP.power)),
        field('right', $._formula),
      )),
    ),

    unary_formula: $ => prec(PREC.unary, seq(
      field('operator', choice('-', '−')),
      field('operand', $._formula),
    )),

    inverse: $ => prec(PREC.inverse, seq($._formula, choice('~', '∼', '⁻¹'))),

    image: $ => prec(PREC.application, seq(
      field('relation', $._formula),
      '[', field('set', $._formula_in_parentheses), ']',
    )),

    call: $ => prec(PREC.application, seq(
      field('function', $._formula),
      '(', $.arguments, ')',
    )),

    arguments: $ => commaSep1($._formula),

    record_field: $ => prec(PREC.application, seq(
      field('record', $._formula),
      "'",
      field('field', $.identifier),
    )),

    builtin_call: $ => seq(
      field('function', alias(choice(...BUILTIN_FUNCTIONS), $.builtin_function)),
      '(', commaSep1($._formula_in_parentheses), ')',
    ),

    _quantified_variables: $ => choice($.identifier_list, seq('(', $.identifier_list, ')')),

    _quantifier_dot: _ => choice('.', '·', '•', '⋅'),

    quantified_predicate: $ => seq(
      field('quantifier', choice('!', '∀', '#', '∃')),
      field('variables', $._quantified_variables),
      $._quantifier_dot,
      '(', field('body', $._formula), ')',
    ),

    quantified_expression: $ => seq(
      field('quantifier', choice(...QUANTIFIED_EXPRESSIONS)),
      field('variables', $._quantified_variables),
      $._quantifier_dot,
      '(',
      field('predicate', $._formula),
      choice('|', '∣'),
      field('body', $._formula_in_parentheses),
      ')',
    ),

    set_comprehension: $ => seq(
      '{',
      field('variables', commaSep1($._formula_in_parentheses)),
      choice(
        seq(choice('|', '∣'), field('predicate', $._formula)),
        // Event-B style {x • P | E}; the ASCII dot would clash with dotted names.
        seq(
          choice('·', '•', '⋅'),
          field('predicate', $._formula),
          choice('|', '∣'),
          field('body', $._formula_in_parentheses),
        ),
      ),
      '}',
    ),

    set_extension: $ => seq('{', commaSep1($._formula_in_parentheses), '}'),

    empty_set: _ => choice(seq('{', '}'), '∅'),

    sequence_extension: $ => seq('[', commaSep1($._formula), ']'),

    empty_sequence: _ => choice(seq('[', ']'), '<>'),

    // `;` and `||` on relations are only allowed inside parentheses.
    _formula_in_parentheses: $ => choice($._formula, $.composition),

    composition: $ => prec.left(PREC.composition, seq(
      field('left', $._formula_in_parentheses),
      field('operator', choice(';', '||', '∥', '‖')),
      field('right', $._formula),
    )),

    parenthesized_formula: $ => seq('(', $._formula_in_parentheses, ')'),

    tuple: $ => seq('(', $._formula_in_parentheses, ',', commaSep1($._formula_in_parentheses), ')'),

    record: $ => seq(
      field('kind', choice('rec', 'struct')),
      '(', commaSep1($.record_entry), ')',
    ),

    record_entry: $ => seq(
      field('field', $.identifier),
      choice(':', '∈'),
      field('value', $._formula),
    ),

    if_formula: $ => seq(
      'IF', field('condition', $._formula),
      'THEN', field('consequence', $._formula),
      repeat(seq('ELSIF', $._formula, 'THEN', $._formula)),
      'ELSE', field('alternative', $._formula),
      'END',
    ),

    let_formula: $ => seq(
      'LET', $.identifier_list,
      'BE', $._formula,
      'IN', $._formula,
      'END',
    ),

    identifier_list: $ => commaSep1($.identifier),

    primed_identifier: $ => seq($.identifier, token.immediate('$0')),

    // ------------------------------------------------------------------
    // Literals and tokens

    boolean: _ => choice('TRUE', 'FALSE', 'btrue', 'bfalse', '⊤', '⊥'),

    builtin_set: _ => choice(...BUILTIN_SETS),

    builtin_constant: _ => choice('MAXINT', 'MININT', 'succ', 'pred', '@prj1', '@prj2'),

    integer: _ => token(choice(/[0-9]+/, /0x[0-9a-fA-F]+/)),

    real: _ => token(/[0-9]+\.[0-9]+([eE][+-]?[0-9]+)?/),

    string: _ => token(choice(
      /"([^"\\\n]|\\.)*"/,
      /'''([^'\\]|\\.|'[^'\\]|''[^'\\])*'''/,
      /```([^`\\]|\\.|`[^`\\]|``[^`\\])*```/,
    )),

    // Dotted names (M.x) are single identifiers; `x.(` stays an identifier
    // followed by the quantifier dot.
    identifier: _ => token(choice(
      /[A-Za-z\u00C0-\u024F\u0391-\u03BA\u03BC-\u03C9\u0400-\u04FF][A-Za-z0-9_\u00C0-\u024F\u0391-\u03C9\u0400-\u04FF]*[\u2080-\u2089]*[\u2032\u2018\u2019]*(\.[A-Za-z][A-Za-z0-9_]*)*/,
      /`([^`\\\n]|\\.)*`/,
    )),

    comment: _ => token(choice(
      seq('//', /[^\n]*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    )),

    pragma: _ => token(prec(1, seq('/*@', /[^*]*\*+([^/*][^*]*\*+)*/, '/'))),
  },
});
