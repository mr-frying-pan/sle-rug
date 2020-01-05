module AST

// import String;

/*
 * Define Abstract Syntax for QL
 *
 * - complete the following data types
 * - make sure there is an almost one-to-one correspondence with the grammar
 */

data AForm(loc src = |tmp:///|)
  = form(str name, list[AQuestion] questions)
  ;

data AQuestion(loc src = |tmp:///|)
  = q(str label, AId name, str t)
  | cq(str label, AId name, str t, AExpr e)
  | cond(AExpr check, list[AQuestion] trueCase, loc src = |tmp:///|)
  | condElse(AExpr check, list[AQuestion] trueCase, list[AQuestion] falseCase, loc src = |tmp:///|)
  | block(list[AQuestion])
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | ival(int i, loc src = |tmp:///|)
  | bval(bool b, loc src = |tmp:///|)
  | sval(str s, loc src = |tmp:///|)
  | neg(AExpr e, loc src = |tmp:///|)
  | mul(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | div(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | add(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | sub(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | gt(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | lt(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | geq(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | leq(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | and(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | or(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | eq(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  | neq(AExpr lhs, AExpr rhs, loc src = |tmp:///|)
  ;

data AId(loc src = |tmp:///|)
  = id(str name, loc src = |tmp:///|);





