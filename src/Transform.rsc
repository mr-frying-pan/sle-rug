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
  = [block([*flatten(q, prevCheck) | q <- qs])];

list[AQuestion] flatten(AQuestion q, AExpr prevCheck)
  = [cond(prevCheck, [q])];

/* Rename refactoring:
 *
 * Write a refactoring transformation that consistently renames all occurrences of the same name.
 * Use the results of name resolution to find the equivalence class of a name.
 *
 */
 
start[Form] rename(start[Form] f, loc useOrDef, str newName, RefGraph refs) {
  if(<useOrDef, _> <- refs[0]) {
    return renameUse(f, useOrDef, newName, refs);
  }
  if(<_, useOrDef> <- refs[1]) {
    return renameDef(f, useOrDef, newName, refs);
  }
  return f;
}
 
start[Form] renameUse(start[Form] f, loc use, str newName, RefGraph refs) {
   Id newX = [Id] newName;
   return visit(f) {
   case (Expr)`<Id x>`
     => (Expr)`<Id newX>`
       when
         <use, loc d> <- refs[2],
         <l, d> <- refs[2],
         l == x@\loc
   case (Question)`<Str _> <Id x> : <Type _>`
     => (Question)`<Str _> <Id newX> : <Type _>`
       when
         <use, loc d> <- refs[2],
         d == x@\loc
   case (Question)`<Str _> <Id x> : <Type _> = <Expr _>`
     => (Question)`<Str _> <Id newX> : <Type _> = <Expr _>`
       when
         <use, loc d> <- refs[2],
         d == x@\loc
   };
}
 
start[Form] renameDef(start[Form] f, loc def, str newName, RefGraph refs) {
   Id newX = [Id]newName;
   return visit(f) {
   case (Question)`<Str _> <Id x> : <Type _>`
     => (Question)`<Str _> <Id newX> : <Type _>`
       when
         def == x@\loc
   case (Question)`<Str _> <Id x> : <Type _> = <Expr _>`
     => (Question)`<Str _> <Id newX> : <Type _> = <Expr _>`
       when
         def == x@\loc
   case (Expr)`<Id x>`
     => (Expr)`<Id newX>`
       when
         <l, def> <- refs[2],
         l == x@\loc
   };
}
 
 
 

