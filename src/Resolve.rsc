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
  // case q(_, AId x, _): insert <x.src, x.name>;
  // case cq(_, AId x, _, _): insert <x.src, x.name>;
  case ref(AId x): us = us + {<x.src, x.name>};
  };
  return us;
}

Def defs(AForm f) {
  ds = {};
  visit(f) {
  case q(_, AId x, _): ds = ds + {<x.name, x.src>};
  case cq(_, AId x, _, _): ds = ds + {<x.name, x.src>};
  }
  return ds;
}