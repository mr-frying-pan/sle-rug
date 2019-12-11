module Syntax

extend lang::std::Layout; // |std:///lang/std/Layout.rsc|;
extend lang::std::Id;
/*
 * Concrete syntax of QL
 */

start syntax Form 
  = "form" Id "{" Question* "}"; 

// TODO: question, computed question, block, if-then-else, if-then
syntax Question
  = Str Id ":" Type Assignment?
  | Block
  | "if" "(" Id ")" Block Else?
  ;
  
syntax Block
  = "{" Question* "}";

syntax Else
  = "else" Block;

syntax Assignment
  = "=" Expr;

// TODO: +, -, *, /, &&, ||, !, >, <, <=, >=, ==, !=, literals (bool, int, str)
// Think about disambiguation using priorities and associativity
// and use C/Java style precedence rules (look it up on the internet)

// TODO: priority rules and associativity
syntax Expr 
  = Id \ "true" \ "false" // true/false are reserved keywords.
  | Int
  | Bool
  | Str
  | "(" Expr ")"
  > "!" Expr
  > left Expr "*" Expr
  | left Expr "/" Expr
  > left Expr "+" Expr
  | left Expr "-" Expr
  > left Expr "&&" Expr
  > left Expr "||" Expr
  > left Expr "\>" Expr
  | left Expr "\<" Expr
  | left Expr "\<=" Expr
  | left Expr "\>=" Expr
  > left Expr "==" Expr
  | left Expr "!=" Expr 
  ;
  
syntax Type
  = "integer" | "str" | "boolean";
  
lexical Str = "\"" [A-Za-z0-9,.?!:;\'\ ]* "\"";

lexical Int 
  = [0-9]+;

lexical Bool = "true" | "false";
