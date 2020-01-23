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

  //writeFile(|project://QL/src| + (f.name + ".js"), form2js(f));
  writeFile(|project://QL/src| + (f.name + ".html"), toString(form2html(f)));
}

HTML5Node form2html(AForm f){
	return
  		html(
  			head(
  				script(src(f.name + ".js")),
  				meta(charset("utf-8")),
             	meta(name("viewport"), content("width=device-width, initial-scale=1, shrink-to-fit=no")),
         
             	link(\rel("stylesheet"), href("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css")),
             
             
             	script(src("https://code.jquery.com/jquery-3.3.1.slim.min.js")),
            	script(src("https://cdnjs.cloudflare.com/ajax/libs/popper.js/1.14.7/umd/popper.min.js")),
             	script(src("https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/js/bootstrap.min.js"))
  				),
  			 	body(
  					h1(id("title"), f.name),
  					div([question2html(q) | AQuestion q <- f.questions])
  			 		)
  				);
}


HTML5Node question2html(AQuestion q){
	switch(q){
		case q(str l, AId aid, str t): 
			return p(l, input(type2html(t), id(aid.name)));
		case cq(str l, AId aid, str t, AExpr exp):
			return p(l, input(type2html(t), id(aid.name), readonly("readonly")));
		case cond(AExpr expr, list[AQuestion] questions):
			return div(id("if" + refId(expr)), 
					html5attr("style", "display:none"),
					question2html(block(questions))
				);
		case condElse(AExpr expr, list[AQuestion] questions1, list[AQuestion] questions2): 
			return div(id("else" + refId(expr)),
						html5attr("style", "display:block"),
						question2html(block(questions1)),
						question2html(block(questions2))
				);
		case block(list[AQuestion] questions): 
			return div([question2html(q) | q <- questions]);
		default: return div();
	}
}

HTML5Attr type2html(str t) {
  switch (t) {
  	case "str": return \type("text");
    case "boolean": return \type("checkbox");
    case "integer": return \type("number");
    default: throw "Unsupported type <t>";
  }
}

str refId(AExpr expr){
str name = "";
	visit(expr) {
		case ref(AId id): { 
		name = id.name;
	}
	}
	return name;
}
