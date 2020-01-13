module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

syntax Question
  = Str Id ":" Type Assignment?
  | Block
  | "if" "(" Expr ")" Block Else?
  ;
  
syntax Block
  = "{" Question* "}";

syntax Else
  = "else" Block;

syntax Assignment
  = "=" Expr;

syntax Expr 
  = Id \ Kwds
  | Int
  | Bool
  | Str
  | "(" Expr ")"
  > "!" Expr
  > left
  ( Expr "*" Expr
  | Expr "/" Expr
  )
  > left 
  ( Expr "+" Expr
  | Expr "-" Expr
  )
  > left
  ( Expr "\>" Expr
  | Expr "\<" Expr
  | Expr "\<=" Expr
  | Expr "\>=" Expr
  )
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > left
  ( Expr "==" Expr
  | Expr "!=" Expr
  )
  ;
  
syntax Type
  = "integer" | "str" | "boolean";
  
lexical Str = "\"" ![\"]* "\"";

lexical Int 
  = "-"?[0-9]+;

lexical Bool = "true" | "false";

keyword Kwds = "if" | "else" | "true" | "false";
