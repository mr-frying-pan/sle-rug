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
  = q(str label, AId name, AType t)
  | cq(str label, AId name, AType t, AExpr e)
  | cond(AExpr check, list[AQuestion] trueCase)
  | condElse(AExpr check, list[AQuestion] trueCase, list[AQuestion] falseCase)
  ;

data AExpr(loc src = |tmp:///|)
  = ref(AId id)
  | ival(int i)
  | bval(bool b)
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

data AId(loc src = |tmp:///|)
  = id(str name, loc src = |tmp:///|);

data AType(loc src = |tmp:///|)
  = tint()
  | tstr()
  | tbool()
  | tunknown();

//AForm implode(start[Form] f)
//  = implode(m.top);
//
//AForm implode((Form)`form <Id name> { <Question* qs> }`)
//  = form("<name>", [ implode(q) | Question q <- qs ]);
//  
//AType implode((Type)`integer`) = tint();
//AType implode((Type)`str`) = tstr();
//AType implode((Type)`boolean`) = tbool();
//AType implode((Type)`<Type t>`) = tunknown();
//
//AQuestion implode((Question)`<Str label> <Id name> : <Type t>`)
//  = q(label, id("<name>", src=name@\loc), implode(t));
//
//AQuestion implode((Question)`<Str label> <Id name> : <Type t> = <Expr exp>`)
//  = cq(label, id("<name>", src=name@\loc), implode(t), implode(exp));
// 
//AExpr implode((Expr)`<Id name>`)
//  = ref(id("<name>", src=name@\loc));
// 
//AExpr implode((Expr)`<Int n>`)
//  = ival(toInt(n));
//  
//AExpr implode((Expr)`<Bool b>`)
//  = bval("<b>" == "true");
//  
//AExpr implode((Expr)`<Str s>`)
//  = sval("<s>");