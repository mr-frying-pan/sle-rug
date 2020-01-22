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
		case q(str l, str id, Type t): {
			qHtml = div(p(l), input(type2html(t), id(id.name)));
			return qHtml;
		}
		case q(str l, str id, Type t, AExpr exp): {
			qHtml = div(p(l), input(type2html(t), id(id.name), readonly([])));
			return qHtml;
		}
		case cond(AExpr expr, list[AQuestion] questions): {
			condHtml = div(id("if" + id.name), class("d-none"),
        	div([question2html[q] | q <- questions]));
			return condHtml;
		}
		case condElse(AExpr expr, list[AQuestion] questions1, list[AQuestion] questions2): {
			condElseHtml = div(div(question2html(cond(expr, questions1))), 
			div(id("else" + id.name), class("d-none"),
			div([question2html[q] | q <- questions2])));
			return condElseHtml;
		}
	};
}

HTML5Attr type2html(Type t) {
  switch (t) {
  	case tstr(): return \type("text");
    case tbool(): return \type("checkbox");
    case tint(): return \type("number");
    default: throw "Unsupported type <t>";
  }
}

//str form2js(AForm f) {
//  return "";
//}
