module Eval

import AST;
import Resolve;
import String;

/*
 * Implement big-step semantics for QL
 */
 
// NB: Eval may assume the form is type- and name-correct.


// Semantic domain for expressions (values)
data Value
  = vint(int n)
  | vbool(bool b)
  | vstr(str s)
  ;

// The value environment
alias VEnv = map[str name, Value \value];

// Modeling user input
data Input
  = input(str question, Value \value);
  
// produce an environment which for each question has a default value
// (e.g. 0 for int, "" for str etc.)
VEnv initialEnv(AForm f) {
  VEnv initVenv = ();
  visit (f) {
  case q(str _, id(str name, src=loc l), "integer"): initVenv += (name : vint(0));
  case q(str _, id(str name, src=loc l), "boolean"): initVenv += (name : vbool(false));
  case q(str _, id(str name, src=loc l), "str"): initVenv += (name : vstr(""));
  }
  return initVenv;
}

// Because of out-of-order use and declaration of questions
// we use the solve primitive in Rascal to find the fixpoint of venv.
VEnv eval(AForm f, Input inp, VEnv venv) {
  return solve (venv) {
    venv = evalOnce(f, inp, venv);
  }
}

VEnv evalOnce(AForm f, Input inp, VEnv venv) {
  for (/AQuestion q := f.questions) {
    venv = eval(q, inp, venv);
  }
  return venv;
}


VEnv eval(AQuestion q, Input inp, VEnv venv) {
  // evaluate conditions for branching,
  // evaluate inp and computed questions to return updated VEnv
  switch (q) {
  	case q(str l, AId id, AType t): {
      if (id.name == inp.question) {
        return (venv + (id: inp.\value));
      }
    }
    case q(str l, AId id, AType t, AExpr expr): {
        return (venv + (id: eval(expr, venv)));
    }
    case cond(AExpr expr, list[AQuestion] questions): {
    	if (eval(expr, venv).b) {
        	for (/AQuestion q := questions) {
          		venv = eval(q, inp, venv);
        	}
        }
    	return venv;	
    	}
    case condElse(AExpr expr, list[AQuestion] questionsIf, list[AQuestion] questionsElse): {
    	if (eval(Expression, venv).b) {
    		for (/AQuestion q := questionsIf) {
    			venv = eval(q, inp, venv);
    		}
    	} else {
    		for (/AQuestion q := questionsElse) {
    			venv = eval(q, inp, venv);
    		}
    	}
    	return venv;
    }
    default: throw "Unsupported expression <q>";
    }
  return ();
}

Value eval(AExpr e, VEnv venv) {
  switch (e) {
    case ival(str n): return vint(toInt(n));
    case bval(str b): return vbool(b == "true");
    case sval(str s): return vstr(s);
    case ref(AId x): return venv[x.name];
    case neg(AExpr e): return vbool(!eval(e, venv).b);
    case mul(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n * eval(rhs, venv).n);
    case div(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n / eval(rhs, venv).n);
    case add(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n + eval(rhs, venv).n);
    case sub(AExpr lhs, AExpr rhs): return vint(eval(lhs, venv).n - eval(rhs, venv).n);
    case gt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n > eval(rhs, venv).n);
    case lt(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n < eval(rhs, venv).n);
    case geq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n >= eval(rhs, venv).n);
    case leq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).n <= eval(rhs, venv).n);
    case and(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b && eval(rhs, venv).b);
    case or(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv).b || eval(rhs, venv).b);
    case eq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) == eval(rhs, venv));
    case neq(AExpr lhs, AExpr rhs): return vbool(eval(lhs, venv) != eval(rhs, venv));
    
    default: throw "Unsupported expression <e>";
  }
}
