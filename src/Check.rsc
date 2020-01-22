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
  case q(l, id(str name), str t, src = loc u): env += <u, name, l, toType(t)>;
  case cq(l, id(str name), str t, _, src = loc u): env += <u, name, l, toType(t)>;
  };
  return env; 
}

set[Message] check(AForm f, TEnv tenv, UseDef useDef) {
  return { *check(q, tenv, useDef) | q <- f.questions }; 
}

// - produce an error if there are declared questions with the same name but different types.
// - duplicate labels should trigger a warning 
// - the declared type computed questions should match the type of the expression.
set[Message] check(q(str qlabel, id(str qname), str qtype, src = loc qloc), TEnv tenv, UseDef useDef) {
  msgs = {};
  for(<loc envloc, str envname, str envlabel, Type envtype> <- tenv) {
    msgs += { error("Duplicate question name", qloc) | qname == envname, toType(qtype) != envtype };
    msgs += { warning("Duplicate labels for <qname> and <envname>", envloc) | qname != envname, qlabel == envlabel};
  }
  return msgs;
}

set[Message] check(cq(str qlabel, id(str qname), str qtype, AExpr qexpr, src = loc qloc), TEnv tenv, UseDef useDef) {
  msgs = {};
  for(<loc envloc, str envname, str envlabel, Type envtype> <- tenv) {
    msgs += { error("Duplicate question name", envloc) | qname == envname, toType(qtype) != envtype };
    msgs += { warning("Duplicate labels for <qname> and <envname>", envloc) | qname != envname, qlabel == envlabel};
  }
  msgs += { *check(qexpr, tenv, useDef) };
  msgs += { error("Expression type differs from question type", qloc) | toType(qtype) != typeOf(qexpr, tenv, useDef) }; 
  return msgs;
}

set[Message] check(cond(AExpr c, list[AQuestion] trueCase, src = loc u),
                   TEnv tenv, UseDef useDef) {
  Type tc = typeOf(c, tenv, useDef);
  return { *check(c, tenv, useDef) }
       + { error("Expected boolean expression, got <toStr(tc)>", u) | tc != tbool() } 
       + { *check(q, tenv, useDef) | q <- trueCase };
}
  
set[Message] check(condElse(AExpr c, list[AQuestion] trueCase, list[AQuestion] falseCase, src = loc u),
                   TEnv tenv, UseDef useDef) {
  Type tc = typeOf(c, tenv, useDef);
  return { *check(c, tenv, useDef) }
       + { error("Expected boolean expression, got <toStr(tc)>", u) | tc != tbool() } 
       + { *check(q, tenv, useDef) | q <- trueCase }
       + { *check(q, tenv, useDef) | q <- falseCase };
}
  
set[Message] check(block(list[AQuestion] qs), TEnv tenv, UseDef useDef)
  = { *check(q, tenv, useDef) | q <- qs };

// Check operand compatibility with operators.
// E.g. for an addition node add(lhs, rhs), 
//   the requirement is that typeOf(lhs) == typeOf(rhs) == tint()

set[Message] check(e:ival(str n, src=loc l), TEnv tenv, UseDef useDef)
  = { error("Incompatible expression type: expected integer", l)
      | typeOf(e, tenv, useDef) != tint() };

set[Message] check(e:bval(str _, src=loc l), TEnv tenv, UseDef useDef)
  = { error("Incompatible expression type: expected boolean", l)
      | typeOf(e, tenv, useDef) != tbool() };

set[Message] check(e:sval(str _, src=loc l), TEnv tenv, UseDef useDef) = {};

set[Message] check(ref(id(str _), src=loc l), TEnv tenv, UseDef useDef)
  = { error("Undefined question", l) | useDef[l] == {} };

set[Message] check(neg(AExpr e), TEnv tenv, UseDef useDef) {
 Type te = typeOf(e, tenv, useDef);
 return { error("Incompatible expression type: expected boolean, got <toStr(te)>", e.src)
          | te != tbool() }
	  + check(e, tenv, useDef);
}

set[Message] check(mul(AExpr lhs, AExpr rhs, src = loc _), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)> ", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(div(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(add(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(sub(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(gt(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(lt(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(geq(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(leq(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected integer, got <toStr(tlhs)>", lhs.src)
          | tlhs != tint() }
      + { error("Incompatible expression type: expected integer, got <toStr(trhs)>", rhs.src)
          | trhs != tint() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(and(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected boolean, got <toStr(tlhs)>", lhs.src)
          | tlhs != tbool() }
      + { error("Incompatible expression type: expected boolean, got <toStr(trhs)>", rhs.src)
          | trhs != tbool() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

set[Message] check(or(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) {
 Type tlhs = typeOf(lhs, tenv, useDef);
 Type trhs = typeOf(rhs, tenv, useDef);
 return { error("Incompatible expression type: expected boolean, got <toStr(tlhs)>", lhs.src)
          | tlhs != tbool() }
      + { error("Incompatible expression type: expected boolean, got <toStr(trhs)>", rhs.src)
          | trhs != tbool() }
      + check(lhs, tenv, useDef)
      + check(rhs, tenv, useDef);
}

// Always type correct. If types do not match the result of the comparison is false.
// eq(AExpr lhs, AExpr rhs)
// neq(AExpr lhs, AExpr rhs)
// Always type correct?
// sval(str s, src = loc l)
default set[Message] check(AExpr _, TEnv _, UseDef _) = {};

Type typeOf(ival(str n), TEnv _, UseDef _) = tint()
  when /(-)?[0-9]+/ := n;
Type typeOf(bval(str b), TEnv _, UseDef _) = tbool()
  when b == "true" || b == "false";
Type typeOf(sval(str s), TEnv _, UseDef _) = tstr();
Type typeOf(ref(id(str x), src = loc u), TEnv tenv, UseDef useDef) = t
  when <u, loc d> <- useDef, <d, x, _, Type t> <- tenv;
default Type typeOf2(AExpr _, TEnv _, UseDef _) = tunknown();
Type typeOf(neg(AExpr x), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(x, tenv, useDef) == tbool();
Type typeOf(and(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool();
Type typeOf(or(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tbool() && typeOf(rhs, tenv, useDef) == tbool();
// always type correct
Type typeOf(eq(AExpr _, AExpr _), TEnv _, UseDef _) = tbool();
Type typeOf(neq(AExpr _, AExpr _), TEnv _, UseDef _) = tbool();
Type typeOf(mul(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tint()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(div(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tint()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(add(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tint()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(sub(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tint()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(gt(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(lt(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(geq(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
Type typeOf(leq(AExpr lhs, AExpr rhs), TEnv tenv, UseDef useDef) = tbool()
  when typeOf(lhs, tenv, useDef) == tint() && typeOf(rhs, tenv, useDef) == tint();
default Type typeOf(AExpr _, TEnv _, UseDef _) = tunknown();

Type toType("integer") = tint();
Type toType("boolean") = tbool();
Type toType("str") = tstr();
default Type toType(str _) = tunknown();

str toStr(tint()) = "integer";
str toStr(tbool()) = "boolean";
str toStr(tstr()) = "str";
default str toStr(Type _) = "unknown";

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
 
 

