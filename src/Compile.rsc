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
  writeFile(|project://QL/compiled| + (f.name + ".js"), form2js(f));
  writeFile(|project://QL/compiled| + (f.name + ".html"), toString(form2html(f)));
}

int conditionalNumber = 0;

HTML5Node form2html(AForm f){
	return
  		html(
  			head(
  			     meta(charset("utf-8")),
  				 script(src(f.name + ".js"))
  				),
  			 	body(
                     [h1(id("title"), f.name)] +
  					 [question2html(q) | q <- f.questions]
  					)
  				);
}

HTML5Node question2html(AQuestion qst){
	switch(qst){
	    case q(str l, AId aid, t:"boolean"):
	      return p(l,
	               input(type2html(t),
	                     id(aid.name),
	                     html5attr("onclick", "click_<aid.name>()")
	                    )
	              );
		case q(str l, AId aid, str t): 
			return p(l,
			         input(type2html(t),
			               id(aid.name),
			               html5attr("oninput", "updateExprs()")
			              )
			        );
		case cq(str l, AId aid, str t, AExpr exp):
			return p(l,
			         input(type2html(t),
			               id(aid.name),
			               class("compQs"),
			               readonly("readonly")
			              )
			        );
		case cond(AExpr expr, list[AQuestion] questions): {
		  n = div([id("cond_<conditionalNumber>"),
		           class("cond"),
                   html5attr("style", "display:none")] +
                   [question2html(q) | q <- questions]
                 );
          conditionalNumber += 1;
          return n;
        }
		case condElse(AExpr expr,
		              list[AQuestion] questions1,
		              list[AQuestion] questions2): 
			return div([id("cond_<conditionalNumber>"),
			            class("cond"),
			            div(
			                [id("cond_<conditionalNumber>_true"),
                            html5attr("style", "display:block")] +
                            [question2html(q) | q <- questions1]
                           ),
                        div(
                            [id("cond_<conditionalNumber>_false"),
                            html5attr("style", "display:block")] +
                            [question2html(q) | q <- questions2]
                           )
                       ]);
		case block(list[AQuestion] questions): 
			return div([question2html(q) | q <- questions] +
			           class("q-block"));
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
  visit(expr) {
    case ref(AId id): return id.name;
    case ival(str i): return "int_" + i;
    case bval(str b): return "bool_" + b;
    case sval(str s): return "str_" + s;
    case neg(AExpr e): return "not_" + refId(e);
    case mul(AExpr lhs, AExpr rhs): return "mul_" + refId(lhs) + "_" + refId(rhs);
    case div(AExpr lhs, AExpr rhs): return "div_" + refId(lhs) + "_" + refId(rhs);
    case add(AExpr lhs, AExpr rhs): return "add_" + refId(lhs) + "_" + refId(rhs);
    case sub(AExpr lhs, AExpr rhs): return "sub_" + refId(lhs) + "_" + refId(rhs);
    case gt(AExpr lhs, AExpr rhs): return "gt_" + refId(lhs) + "_" + refId(rhs);
    case lt(AExpr lhs, AExpr rhs): return "lt_" + refId(lhs) + "_" + refId(rhs);
    case geq(AExpr lhs, AExpr rhs): return "geq_" + refId(lhs) + "_" + refId(rhs);
    case leq(AExpr lhs, AExpr rhs): return "leq_" + refId(lhs) + "_" + refId(rhs);
    case and(AExpr lhs, AExpr rhs): return "and_" + refId(lhs) + "_" + refId(rhs);
    case or(AExpr lhs, AExpr rhs): return "or_" + refId(lhs) + "_" + refId(rhs);
    case eq(AExpr lhs, AExpr rhs): return "eq_" + refId(lhs) + "_" + refId(rhs);
    case neq(AExpr lhs, AExpr rhs): return "neq_" + refId(lhs) + "_" + refId(rhs);
  }
  return name;
}

str defaultValue(str t) {
  switch (t) {
    case "boolean": "false";
    case "integer": "0";
    case "str": "\"\"";
  }
  return "";
}

str form2js(AForm f) {
  int condNumber = 0;
  str js =
  "function updateExprs() {
  '  var evt = new CustomEvent(\'update\');
  '  [].forEach.call( document.getElementsByTagName(\"*\"),
  '    function(elem) {
  '      elem.dispatchEvent(evt, {target: elem});
  '    });
  '}
  '
  'window.onload = function () {
  '  conds = document.getElementsByClassName(\'cond\');
  '  computedQs = document.getElementsByClassName(\'compQs\');
  '  for(var c of conds) {
  '    c.addEventListener(\'update\', window[\"fun_\" + c.id], false);
  '  }
  '  for(var c of computedQs) {
  '    c.addEventListener(\'update\', window[\"fun_\" + c.id], false);
  '  }
  '  updateExprs();
  '}\n";

  top-down visit(f) {
  case q(str _, id(str name), "boolean"): {
    js +=
    "function click_<name> (e) {
    '  var thisElement = document.getElementById(\"<name>\");
    '  thisElement.value = thisElement.checked ? 1 : 0;
    '  updateExprs();
    '}
    "; }
  case cq(str _, id(str name), str t, AExpr expr):
    js +=
    "function fun_<name> (e) {
    '  <for (/ref(id(str vname)) := expr) {>
    '  var <vname> = document.getElementById(\"<vname>\").value;
    '  <}>
    '  var <name> = document.getElementById(\"<name>\");
    '  <if (t == "boolean") {>
    '  <name>.checked = <expr2js(expr)>;
    '  <name>.value = <name>.checked ? 1 : 0;
    '  <} else {>
    '  <name>.value = <expr2js(expr)>;
    '  <}>
    '}\n";
  case cond(AExpr check, _): {
    js +=
    "function fun_cond_<condNumber> (e) {
    '    <for (/ref(id(str vname)) := check) {>
    '    var <vname> = document.getElementById(\"<vname>\").value;
    '    <}>
    '    var trueCase = document.getElementById(\"cond_<condNumber>\");
    '    var condition = <expr2js(check)> == true;
    '    if (condition) {
    '      trueCase.style.display = \"block\";
    '    }
    '    else {
    '      trueCase.style.display = \"none\";
    '    }
    '  }
    '";
    condNumber += 1;
  }
  case condElse(AExpr check, _, _): {
   	js +=
    "function fun_cond_<condNumber> (e) {
    '    <for (/ref(id(str vname)) := expr) {>
    '    var <vname> = document.getElementById(\"<vname>\").value;
    '    <}>
    '    var trueCase = document.getElementById(\"cond_<condNumber>_true\");
    '    var falseCase = document.getElementById(\"cond_<condNumber>_false\");
    '    var condition = <expr2js(check)> == true;
    '    if (condition) {
    '      trueCase.style.display = \"block\";
    '      falseCase.style.display = \"none\";
    '    }
    '    else {
    '      trueCase.style.display = \"none\";
    '      falseCase.style.display = \"block\";
    '    }
    '  }
    '";
    condNumber += 1;
  }
  }
  return js;
}

str expr2js(AExpr expr) {
  switch (expr) {
    case ref(id(name)):
    	return name;
    case bval(str b):
    	return "<b>";
    case ival(str i):
    	return "<i>";
    case sval(str s):
    	return "<s>";
    case neg(AExpr e):
    	return "!<expr2js(e)>";
    case mul(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> * <expr2js(rhs)>)";
    case div(AExpr lhs, AExpr rhs):
		return "(<expr2js(lhs)> / <expr2js(rhs)>)";
    case add(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> + <expr2js(rhs)>)";
    case sub(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> - <expr2js(rhs)>)";
    case gt(AExpr lhs, AExpr rhs):
		return "(<expr2js(lhs)> \> <expr2js(rhs)>)";
    case lt(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> \< <expr2js(rhs)>)";
    case leq(AExpr lhs, AExpr rhs):
		return "(<expr2js(lhs)> \<= <expr2js(rhs)>)";
    case geq(AExpr lhs, AExpr rhs):
		return "(<expr2js(lhs)> \>= <expr2js(rhs)>)";
    case and(AExpr lhs, AExpr rhs):
		return "(<expr2js(lhs)> && <expr2js(rhs)>)";
    case or(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> || <expr2js(rhs)>)";
    case eq(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> === <expr2js(rhs)>)";
    case neq(AExpr lhs, AExpr rhs):
    	return "(<expr2js(lhs)> !== <expr2js(rhs)>)";
    default:
    	throw "Unsupported expression <expr>";
  }
}


