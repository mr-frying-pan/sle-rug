module Check

import AST;
import Resolve;
import Message; // see standard library

import IO;

import Set;

data Type
  = tint()
  | tbool()
  | tstr()
  | tunknown()
  ;

// the type environment consisting of defined questions in the form 
alias TEnv = rel[loc def, str name, str label, Type \type];

// To avoid recursively traversing the form, use the `visit` construct
// or deep match (e.g., `for (/question(...) := f) {...}` ) 
TEnv collect(AForm f) {
  env = {};
  visit(f) {
  case q(l, AId x, str t): env += <x.src, x.name, l, toType(t)>;
  case cq(l, AId x, str t, _): env += <x.src, x.name, l, toType(t)>;
  };
  return env; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return { *check(q, tenv, useDef) | q <- f.questions }; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(q(str qlabel, id(str qname, src = loc qloc), str qtype), TEnv tenv, UseDef useDef) {
  msgs = {};
  for(<loc envloc, str envname, str envlabel, Type envtype> <- tenv) {
    msgs += { error("Duplicate question name", d) | qname == envname, toType(qtype) != envtype };
    msgs += { warning("Duplicate labels for <qname> and <envname>", envloc) | qname != envname, qlabel == envlabel};
  }
  return msgs;
}

set[Message] check(cq(str qlabel, id(str qname, src = loc qloc), str qtype, AExpr qexpr), TEnv tenv, UseDef useDef) {
  msgs = {};
  for(<loc envloc, str envname, str envlabel, Type envtype> <- tenv) {
    msgs += { error("Duplicate question name", envloc) | qname == envname, toType(qtype) != envtype };
    msgs += { warning("Duplicate labels for <qname> and <envname>", envloc) | qname != envname, qlabel == envlabel};
  }
  msgs += { *check(qexpr, tenv, useDef) }
          + { error("Expression type differs from question type", qloc) | toType(qtype) != typeOf(qexpr, tenv, useDef) }; 
  return msgs;
}

set[Message] check(cond(AExpr c, list[AQuestion] trueCase, src = loc u),
                   TEnv tenv, UseDef useDef)
  = { *check(c, tenv, useDef) }
  + { error("Boolean expression expected", u) | typeOf(c, tenv, useDef) != tbool() } 
  + { *check(q, tenv, useDef) | q <- trueCase };
  
set[Message] check(condElse(AExpr c, list[AQuestion] trueCase, list[AQuestion] falseCase, src = loc u),
                   TEnv tenv, UseDef useDef)
  = { *check(c, tenv, useDef) }
  + { error("Boolean expression expected", u) | typeOf(c, tenv, useDef) != tbool() } 
  + { *check(q, tenv, useDef) | q <- trueCase }
  + { *check(q, tenv, useDef) | q <- falseCase };
  
set[Message] check(block(list[AQuestion] qs), TEnv tenv, UseDef useDef)
  = { *check(q, tenv, useDef) | q <- qs };

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()
set[Message] check(AExpr e, TEnv tenv, UseDef useDef) {
  set[Message] msgs = {};
  tOfE = typeOf(e, tenv, useDef);
  switch (e) {
    case ref(id(str name, src = loc u)):
      msgs += { error("Undefined question", u) | useDef[u] == {} };
	case neg(AExpr e):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tbool() };
    case mul(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case div(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case add(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
    case sub(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case gt(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case lt(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case geq(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case leq(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tint()};
	case and(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tbool()};
	case or(AExpr lhs, AExpr rhs):
	  msgs += { error("Incompatible expression type", e.src) | tOfE != tbool()};
	// Always type correct. If types do not match the result of the comparison is false.
	// case eq(AExpr lhs, AExpr rhs):
	// case neq(AExpr lhs, AExpr rhs):
  }
  
  return msgs; 
}

Type typeOf(ival(int _), TEnv _, UseDef _) = tint();
Type typeOf(bval(bool _), TEnv _, UseDef _) = tbool();
Type typeOf(sval(str _), TEnv _, UseDef _) = tstr();
Type typeOf(ref(id(str x, src = loc u)), TEnv tenv, UseDef useDef) = t
  when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv;
Type typeOf(neg(AExpr x), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(x, tenv, useDef) == tbool();
Type typeOf(and(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool();
Type typeOf(or(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool();
// always type correct
Type typeOf(eq(AExpr _, AExpr _), TEnv _, UseDef _) = tbool();
Type typeOf(neq(AExpr _, AExpr _), TEnv _, UseDef _) = tbool();
// mul div add sub gt lt geq leq
Type typeOf(_(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tint()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();

Type toType("integer") = tint();
Type toType("boolean") = tbool();
Type toType("str") = tstr();
default Type toType(str _) = tunknown();

/* 
 * Pattern-based dispatch style:
 * 
 * Type typeOf(ref(str x, src = loc u), TEnv tenv, UseDef useDef) = t
 *   when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv
 *
 * ... etc.
 * 
 * default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();
 *
 */
 
 

