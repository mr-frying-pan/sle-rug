module Syntax

extend lang::std::Layout;
extend lang::std::Id;

/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

syntax Question
  = Str Id ":" Type "=" Expr
  | Str Id ":" Type 
  | Block
  | "if" "(" Expr ")" Block
  | "if" "(" Expr ")" Block "else" Block
  ;
  
syntax Block
  = "{" Question* "}";

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
  = "-"?[1-9][0-9]*
  | [0];

lexical Bool = "true" | "false";

keyword Kwds = "if" | "else" | "true" | "false";
