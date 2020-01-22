module Compile

import AST;
import Check;
import Resolve;
import IO;
import lang::html5::DOM; // see standard library

/*
 * Implement a compiler for QL to HTML and Javascript
 *
 * - assume the form is type- and name-correct
 * - separate the compiler in two parts form2html and form2js producing 2 files
 * - use string templates to generate Javascript
 * - use the HTML5Node type and the `str toString(HTML5Node x)` function to format to string
 * - use any client web framework (e.g. Vue, React, jQuery, whatever) you like for event handling
 * - map booleans to checkboxes, strings to textfields, ints to numeric text fields
 * - be sure to generate uneditable widgets for computed questions!
 * - if needed, use the name analysis to link uses to definitions
 */

void compile(AForm f) {
  writeFile(f.src[extension="js"].top, form2js(f));
  writeFile(f.src[extension="html"].top, toString(form2html(f)));
}

HTML5Node form2html(AForm f) {
return
	html(
    	       head(
        	     title(f.name), meta(charset("utf-8"), name("viewport"), content("width=device-width, initial-scale=1, shrink-to-fit=no")),
  	             link(\rel("stylesheet"), href("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css")),
	 			 script(src("https://code.jquery.com/jquery-3.4.1.slim.min.js")),
				 script(src("https://cdn.jsdelivr.net/npm/popper.js@1.16.0/dist/umd/popper.min.js")),
				 script(src("https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/js/bootstrap.min.js")),
				 script(src(f.src[extension="js"].file)) 
 	          ),
  	         body(
 	            div(
 	              div(
 	                [question2html(q) | q <- f.questions]
 	              )
 	            )
 	          )
 	        );
}
         
HTML5Node question2html(AQuestion q){
	switch(q){
		case q(str l, AId id, str t): {
			qHtml = div(p(l), input(type2html(t), id(id.name)));
			return qHtml;
		}
		case cq(str l, AId id, str t, AExpr exp): {
			qHtml = div(p(l), input(type2html(t), id(id.name), readonly([])));
			return qHtml;
		}
		case block(list[AQuestion] questions): {
			blockHtml = div(
            [question2html(q) | q <- questions]
            );
             return blockHtml;
		}
		case cond(AExpr expr, list[AQuestion] questions): {
			condHtml = div(id("if" + id.name), class("d-none"),
        	div([question2html(q) | q <- questions]));
			return condHtml;
		}
		case condElse(AExpr expr, list[AQuestion] questions1, list[AQuestion] questions2): {
			condElseHtml = div(div(question2html(cond(expr, questions1))), 
			div(id("else" + id.name), class("d-none"),
			div([question2html(q) | q <- questions2])));
			return condElseHtml;
		}
		default: return div();
	}
}

HTML5Attr type2html(str t) {
  switch (t) {
  	case String(): return \type("text");
    case Boolean(): return \type("checkbox");
    case Integer(): return \type("number");
    default: throw "Unsupported type <t>";
  }
}

str form2js(AForm f) {
  return "";
}

str expr2js(AExpr expr) {
  switch (expr) {
    case ref(id(name)):
    	return name;
    case bval(Bool b):
    	return "<b>";
    case ival(Int i):
    	return "<i>";
    case sval(Str s):
    	return "<s>";
    case par(Aexpr e):
    	return "(<expr2js(e)>)";
    case neg(Aexpr e):
    	return "!<expr2js(e)>";
    case mul(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> * <expr2js(rhs)>)";
    case div(Aexpr lhs, Aexpr rhs):
		return "(<expr2js(lhs)> / <expr2js(rhs)>)";
    case add(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> + <expr2js(rhs)>)";
    case sub(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> - <expr2js(rhs)>)";
    case gt(Aexpr lhs, Aexpr rhs):
		return "(<expr2js(lhs)> \> <expr2js(rhs)>)";
    case lt(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> \< <expr2js(r)>)";
    case leq(Aexpr lhs, Aexpr rhs):
		return "(<expr2js(lhs)> \<= <expr2js(rhs)>)";
    case geq(Aexpr lhs, Aexpr rhs):
		return "(<expr2js(lhs)> \>= <expr2js(rhs)>)";
    case and(Aexpr lhs, Aexpr rhs):
		return "(<expr2js(lhs)> && <expr2js(rhs)>)";
    case or(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> || <expr2js(rhs)>)";
    case eq(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> == <expr2js(rhs)>)";
    case neq(Aexpr lhs, Aexpr rhs):
    	return "(<expr2js(lhs)> != <expr2js(rhs)>)";
    default:
    	throw "Unsupported expression <e>";
  }
}
