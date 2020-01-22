module Resolve

import AST;

/*
 * Name resolution for QL
 */ 


// modeling declaring occurrences of names
alias Def = rel[str name, loc def];

// modeling use occurrences of names
alias Use = rel[loc use, str name];

alias UseDef = rel[loc use, loc def];

// the reference graph
alias RefGraph = tuple[
  Use uses, 
  Def defs, 
  UseDef useDef
]; 

RefGraph resolve(AForm f) = <us, ds, us o ds>
  when Use us := uses(f), Def ds := defs(f);

Use uses(AForm f) {
  us = {};
  visit(f) {
  case ref(id(str name), src = loc l): us += <l, name>;
  };
  return us;
}

Def defs(AForm f) {
  ds = {};
  visit(f) {
  case q(_, id(str name), _, src = loc l): ds += <name, l>;
  case cq(_, id(str name), _, _, src = loc l): ds += <name, l>;
  }
  return ds;
}