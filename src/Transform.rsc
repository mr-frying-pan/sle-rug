module Transform

import Syntax;
import Resolve;
import AST;

import ParseTree;

/* 
 * Transforming QL forms
 */
 
 
/* Normalization:
 *  wrt to the semantics of QL the following
 *     q0: "" int;
 *     if (a) { 
 *        if (b) { 
 *          q1: "" int; 
 *        } 
 *        q2: "" int; 
 *      }
 *
 *  is equivalent to
 *     if (true) q0: "" int;
 *     if (true && a && b) q1: "" int;
 *     if (true && a) q2: "" int;
 *
 * Write a transformation that performs this flattening transformation.
 */
 
AForm flatten(AForm f) {
  AExpr prevCheck = bval("true");
  f.questions = [*flatten(q, prevCheck) | q <- f.questions];
  return f; 
}

list[AQuestion] flatten(cond(AExpr c, list[AQuestion] qs), AExpr prevCheck)
  = [*flatten(q, and(prevCheck, c)) | q <- qs];
  
list[AQuestion] flatten(condElse(AExpr c, list[AQuestion] trueCase, list[AQuestion] falseCase)
                        , AExpr prevCheck)
  = [*flatten(q, and(prevCheck, c)) | q <- trueCase]
  + [*flatten(q, and(prevCheck, neg(c))) | q <- falseCase];

list[AQuestion] flatten(block(list[AQuestion] qs), AExpr prevCheck)
  = [*flatten(q, prevCheck) | q <- qs];

list[AQuestion] flatten(AQuestion q, AExpr prevCheck)
  = [cond(prevCheck, [q])];

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, UseDef useDef) {
   for(<loc use, loc def> <- useDef) {
     if(use == useOrDef) {
       return renameUse(f, use, newName, useDef);
     }
     else if(def == useOrDef) {
       return renameDef(f, def, newName, useDef);
     }
   }
   return f;
}
 
start[Form] renameUse(start[Form] f, loc use, str newName, UseDef useDef) {
   Id newX = [Id] newName;
   return visit(f) {
   case (Expr)`<Id x>`
     => (Expr)`<Id newX>`
       when
         <use, d> <- useDef,
         <l, d> <- useDef,
         l == x@\loc
   };
}
 
start[Form] renameDef(start[Form] f, loc def, str newName, UseDef useDef) {
   Id newX = [Id]newName;
   return visit(f) {
   case (Question)`<Str _> <Id x> : <Type _>` => (Question)`<Str _> <Id newX> : <Type _>`
     when
       <u, def> <- useDef,
       u == x@\loc
   };
}
 
 
 

