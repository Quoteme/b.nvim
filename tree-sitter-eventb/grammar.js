/**
 * @file Event-B grammar for tree-sitter: machines and contexts in Camille notation.
 * @license EPL-2.0
 *
 * The component structure follows ProB's EventBParser.scc (hhu-stups/probparsers);
 * formulas follow Rodin's mathematical language, in Unicode or ASCII.
 */

/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

const PREC = {
  quantifier: 1, // bodies extend as far to the right as possible
  implies: 2,
  and_or: 3,
  not: 4,
  relation: 5,
  arrow: 6,
  set_op: 7,
  interval: 8,
  additive: 9,
  multiplicative: 10,
  power: 11,
  unary: 12,
  postfix: 13,
};

const OP = {
  implies: ['⇔', '<=>', '⇒', '=>'],
  and_or: ['∧', '&', '∨', 'or'],
  relation: [
    '=', '≠', '/=', '∈', ':', '∉', '/:', '⊂', '<<:', '⊄', '/<<:', '⊆', '<:', '⊈', '/<:',
    '<', '≤', '<=', '>', '≥', '>=',
  ],
  arrow: [
    '↔', '<->', '', '<<->', '', '<->>', '', '<<->>',
    '⇸', '+->', '→', '-->', '⤔', '>+>', '↣', '>->', '⤀', '+->>', '↠', '->>', '⤖', '>->>',
  ],
  set_op: [
    '∪', '\\/', '∩', '/\\', '∖', '\\', '×', '**', '◁', '<|', '⩤', '<<|', '▷', '|>', '⩥', '|>>',
    '', '<+', ';', '∘', 'circ', '⊗', '><', '∥', '||', '↦', '|->',
  ],
  additive: ['+', '−', '-'],
  multiplicative: ['∗', '*', '÷', '/', 'mod'],
};

const BUILTIN_FUNCTIONS = [
  'card', 'dom', 'ran', 'min', 'max', 'union', 'inter', 'bool', 'finite', 'partition',
  'ℙ', 'POW', 'ℙ1', 'POW1',
];

const BUILTIN_SETS = ['ℕ', 'NAT', 'ℕ1', 'NAT1', 'ℤ', 'INT', 'BOOL'];

const BUILTIN_CONSTANTS = ['id', 'prj1', 'prj2', 'pred', 'succ'];

/**
 * @param {RuleOrLiteral} rule
 */
function commaSep1(rule) {
  return seq(rule, repeat(seq(',', rule)));
}

/** @param {string[]} spellings */
function op(spellings) {
  return choice(...spellings);
}

module.exports = grammar({
  name: 'eventb',

  extras: $ => [/\s/, $.comment],

  word: $ => $.identifier,

  conflicts: $ => [
    // `{x, y` may start a set extension, a comprehension or a pattern.
    [$._formula, $.set_comprehension],
  ],

  rules: {
    source_file: $ => choice($.machine, $.context),

    // ------------------------------------------------------------------
    // Machines

    machine: $ => seq(
      'machine',
      field('name', $.identifier),
      optional($.refines_clause),
      optional($.sees_clause),
      optional($.variables_clause),
      optional($.invariants_clause),
      optional($.variant_clause),
      optional($.events_clause),
      'end',
    ),

    refines_clause: $ => seq('refines', repeat1($.identifier)),

    sees_clause: $ => seq('sees', repeat1($.identifier)),

    variables_clause: $ => seq('variables', repeat1($.identifier)),

    invariants_clause: $ => seq('invariants', repeat1($.invariant)),

    invariant: $ => seq(
      optional('theorem'),
      field('label', $.label),
      field('predicate', $._formula),
    ),

    variant_clause: $ => seq('variant', $._formula),

    events_clause: $ => seq('events', repeat1($.event)),

    event: $ => seq(
      optional(field('convergence', choice('ordinary', 'convergent', 'anticipated'))),
      'event',
      field('name', $.identifier),
      optional(choice(
        seq('refines', repeat1(field('refines', $.identifier))),
        seq('extends', field('extends', $.identifier)),
      )),
      optional(seq('any', repeat1($.parameter))),
      optional(seq(choice('where', 'when'), repeat1($.guard))),
      optional(seq('with', repeat1($.witness))),
      optional(seq(choice('then', 'begin'), repeat1($.action))),
      'end',
    ),

    parameter: $ => $.identifier,

    guard: $ => seq(
      optional('theorem'),
      field('label', $.label),
      field('predicate', $._formula),
    ),

    witness: $ => seq(field('label', $.label), field('predicate', $._formula)),

    action: $ => seq(field('label', $.label), field('assignment', $._assignment)),

    // ------------------------------------------------------------------
    // Contexts

    context: $ => seq(
      'context',
      field('name', $.identifier),
      optional($.extends_clause),
      optional($.sets_clause),
      optional($.constants_clause),
      optional($.axioms_clause),
      'end',
    ),

    extends_clause: $ => seq('extends', repeat1($.identifier)),

    sets_clause: $ => seq('sets', repeat1($.carrier_set)),

    carrier_set: $ => $.identifier,

    constants_clause: $ => seq('constants', repeat1($.constant)),

    constant: $ => $.identifier,

    axioms_clause: $ => seq('axioms', repeat1($.axiom)),

    axiom: $ => seq(
      optional('theorem'),
      field('label', $.label),
      field('predicate', $._formula),
    ),

    // ------------------------------------------------------------------
    // Assignments

    _assignment: $ => choice($.becomes_equal_to, $.becomes_member_of, $.becomes_such_that),

    becomes_equal_to: $ => seq(
      field('left', commaSep1($.identifier)),
      choice('≔', ':='),
      field('right', commaSep1($._formula)),
    ),

    becomes_member_of: $ => seq(
      field('left', $.identifier),
      choice(':∈', '::'),
      field('right', $._formula),
    ),

    becomes_such_that: $ => seq(
      field('left', commaSep1($.identifier)),
      choice(':∣', ':|'),
      field('predicate', $._formula),
    ),

    // ------------------------------------------------------------------
    // Predicates and expressions

    _formula: $ => choice(
      $.binary_formula,
      $.unary_formula,
      $.quantified_predicate,
      $.quantified_expression,
      $.inverse,
      $.call,
      $.image,
      $.builtin_call,
      $.set_extension,
      $.set_comprehension,
      $.empty_set,
      $.parenthesized_formula,
      $.identifier,
      $.integer,
      $.boolean,
      $.builtin_set,
      $.builtin_constant,
    ),

    binary_formula: $ => choice(
      ...[
        [PREC.implies, OP.implies],
        [PREC.and_or, OP.and_or],
        [PREC.relation, OP.relation],
        [PREC.arrow, OP.arrow],
        [PREC.set_op, OP.set_op],
        [PREC.interval, ['‥', '..']],
        [PREC.additive, OP.additive],
        [PREC.multiplicative, OP.multiplicative],
      ].map(([precedence, operators]) => prec.left(/** @type {number} */ (precedence), seq(
        field('left', $._formula),
        field('operator', op(/** @type {string[]} */ (operators))),
        field('right', $._formula),
      ))),
      prec.right(PREC.power, seq(
        field('left', $._formula),
        field('operator', '^'),
        field('right', $._formula),
      )),
    ),

    unary_formula: $ => choice(
      prec(PREC.not, seq(field('operator', choice('¬', 'not')), field('operand', $._formula))),
      prec(PREC.unary, seq(field('operator', choice('−', '-')), field('operand', $._formula))),
    ),

    _dot: _ => choice('·', '.'),

    _mid: _ => choice('∣', '|'),

    quantified_predicate: $ => prec.right(PREC.quantifier, seq(
      field('quantifier', choice('∀', '!', '∃', '#')),
      field('variables', $.identifier_list),
      $._dot,
      field('body', $._formula),
    )),

    quantified_expression: $ => prec.right(PREC.quantifier, seq(
      field('quantifier', choice('λ', '%', '⋃', 'UNION', '⋂', 'INTER')),
      field('pattern', $._formula),
      $._dot,
      field('predicate', $._formula),
      $._mid,
      field('body', $._formula),
    )),

    identifier_list: $ => commaSep1($.identifier),

    inverse: $ => prec(PREC.postfix, seq($._formula, choice('∼', '~'))),

    call: $ => prec(PREC.postfix, seq(
      field('function', $._formula),
      '(', commaSep1($._formula), ')',
    )),

    image: $ => prec(PREC.postfix, seq(
      field('relation', $._formula),
      '[', field('set', $._formula), ']',
    )),

    builtin_call: $ => seq(
      field('function', alias(choice(...BUILTIN_FUNCTIONS), $.builtin_function)),
      '(', commaSep1($._formula), ')',
    ),

    set_extension: $ => seq('{', commaSep1($._formula), '}'),

    // {x · P ∣ E} and {E ∣ P}
    set_comprehension: $ => seq(
      '{',
      choice(
        seq(
          field('variables', commaSep1($.identifier)),
          $._dot,
          field('predicate', $._formula),
          $._mid,
          field('body', $._formula),
        ),
        seq(field('body', $._formula), $._mid, field('predicate', $._formula)),
      ),
      '}',
    ),

    empty_set: _ => choice('∅', seq('{', '}')),

    parenthesized_formula: $ => seq('(', $._formula, ')'),

    // ------------------------------------------------------------------
    // Tokens

    boolean: _ => choice('TRUE', 'FALSE', '⊤', 'true', '⊥', 'false'),

    builtin_set: _ => choice(...BUILTIN_SETS),

    builtin_constant: _ => choice(...BUILTIN_CONSTANTS),

    integer: _ => /[0-9]+/,

    label: _ => token(seq('@', /[^\s]+/)),

    identifier: _ => /[A-Za-z_À-ɏΑ-κμ-ωЀ-ӿ][A-Za-z0-9_À-ɏΑ-κμ-ωЀ-ӿ]*'?/,

    comment: _ => token(choice(
      seq('//', /[^\n]*/),
      seq('/*', /[^*]*\*+([^/*][^*]*\*+)*/, '/'),
    )),
  },
});
