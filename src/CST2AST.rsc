module CST2AST

import Syntax;
import AST;

import ParseTree;
import String;

/*
 * Implement a mapping from concrete syntax trees (CSTs) to abstract syntax trees (ASTs)
 *
 * - Use switch to do case distinction with concrete patterns (like in Hack your JS) 
 * - Map regular CST arguments (e.g., *, +, ?) to lists 
 *   (NB: you can iterate over * / + arguments using `<-` in comprehensions or for-loops).
 * - Map lexical nodes to Rascal primitive types (bool, int, str)
 * - See the ref example on how to obtain and propagate source locations.
 */

// this function is never called. What is it's purpose?
// ok, this function is called by the IDE
AForm cst2ast(start[Form] sf) {
  Form f = sf.top; // remove layout before and after form
  return cst2ast(f);
}

AForm cst2ast((Form)`form <Id x> { <Question* qs> }`) {
	return form("<x>", [cst2ast(q) | Question q <- qs]);
}

AQuestion cst2ast(Question question) {
  switch(question) {
  	case (Question)`<Str label> <Id name> : <Type t>`:
        // It'd be nice to be able to extract it using concrete syntax but it does not work that way
		return q(replaceLast(replaceFirst("<label>", "\"", ""), "\"", ""), id("<name>"), "<t>", src = name@\loc);
  	case (Question)`<Str label> <Id name> : <Type t> = <Expr e>`:
  		// same as above
  		return cq(replaceLast(replaceFirst("<label>", "\"", ""), "\"", ""), id("<name>"), "<t>", cst2ast(e), src=name@\loc);
  	case (Question)`if ( <Expr bexpr> ) <Block trueBlock>`:
  		return cond(cst2ast(bexpr), cst2ast(trueBlock), src=bexpr@\loc);
  	case (Question)`if ( <Expr bexpr> ) <Block trueBlock> else <Block falseBlock>`:
  		return condElse(cst2ast(bexpr), cst2ast(trueBlock), cst2ast(falseBlock), src=bexpr@\loc);
  	case (Question)`{ <Question* qs> }`:
  		return block([cst2ast(q) | q <- qs]);
  	default: throw "Unrecognized question: <q>";
  }
}

AExpr cst2ast(Expr e) {
  switch (e) {
    case (Expr)`<Id x>`: return ref(id("<x>"), src=x@\loc);
    case (Expr)`<Int i>`: return ival("<i>", src=e@\loc);
    case (Expr)`<Bool b>`: return bval("<b>", src=e@\loc);
    case (Expr)`<Str s>`: return sval("<s>", src=e@\loc);
    case (Expr)`( <Expr ex> )`: return cst2ast(ex);
    case (Expr)`! <Expr ex>`: return neg(cst2ast(ex), src=e@\loc);
    case (Expr)`<Expr lhs> * <Expr rhs>`: return mul(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> / <Expr rhs>`: return div(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> + <Expr rhs>`: return add(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> - <Expr rhs>`: return sub(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \> <Expr rhs>`: return gt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \< <Expr rhs>`: return lt(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \>= <Expr rhs>`: return geq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> \<= <Expr rhs>`: return leq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> && <Expr rhs>`: return and(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> || <Expr rhs>`: return or(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> == <Expr rhs>`: return eq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    case (Expr)`<Expr lhs> != <Expr rhs>`: return neq(cst2ast(lhs), cst2ast(rhs), src=e@\loc);
    default: throw "Unhandled expression: <e>";
  }
}

list[AQuestion] cst2ast((Block)`{ <Question* qs> }`) = [cst2ast(q) | q <- qs];





