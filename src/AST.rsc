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
  | cond(AExpr check, list[AQuestion] trueCase)
  | condElse(AExpr check, list[AQuestion] trueCase, list[AQuestion] falseCase)
  | block(list[AQuestion])
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | ival(str i)
  | bval(str b)
  | sval(str s)
  | neg(AExpr e)
  | mul(AExpr lhs, AExpr rhs)
  | div(AExpr lhs, AExpr rhs)
  | add(AExpr lhs, AExpr rhs)
  | sub(AExpr lhs, AExpr rhs)
  | gt(AExpr lhs, AExpr rhs)
  | lt(AExpr lhs, AExpr rhs)
  | geq(AExpr lhs, AExpr rhs)
  | leq(AExpr lhs, AExpr rhs)
  | and(AExpr lhs, AExpr rhs)
  | or(AExpr lhs, AExpr rhs)
  | eq(AExpr lhs, AExpr rhs)
  | neq(AExpr lhs, AExpr rhs)
  ;

data AId
  = id(str name);





