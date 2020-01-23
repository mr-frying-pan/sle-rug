window.onload = function () {
  conds = document.getElementsByClassName('cond');
  computedQs = document.getElementsByClassName('compQs');
  for(var c of conds) {
    c.addEventListener('update', window["fun_" + c.id], false);
  }
  for(var c of computedQs) {
    c.addEventListener('update', window["fun_" + c.id], false);
  }
}

function updateExprs() {
  var evt = new CustomEvent('update');
  [].forEach.call( document.getElementsByTagName("*"),
    function(elem) {
      elem.dispatchEvent(evt, {target: elem});
    });
}
function click_hasBoughtHouse (e) {
  var thisElement = document.getElementById("hasBoughtHouse");
  thisElement.value = thisElement.checked ? 1 : 0;
  updateExprs();
}
    function click_hasMaintLoan (e) {
  var thisElement = document.getElementById("hasMaintLoan");
  thisElement.value = thisElement.checked ? 1 : 0;
  updateExprs();
}
    function click_hasSoldHouse (e) {
  var thisElement = document.getElementById("hasSoldHouse");
  thisElement.value = thisElement.checked ? 1 : 0;
  updateExprs();
}
    function fun_cond_0 (e) {
    
    var hasSoldHouse = document.getElementById("hasSoldHouse").value;
    
    var trueCase = document.getElementById("cond_0");
    var condition = hasSoldHouse == true;
    if (condition) {
      trueCase.style.display = "block";
    }
    else {
      trueCase.style.display = "none";
    }
  }
function fun_valueResidue (e) {
  
  var sellingPrice = document.getElementById("sellingPrice").value;
  
  var privateDebt = document.getElementById("privateDebt").value;
  
  var valueResidue = document.getElementById("valueResidue");
  
  valueResidue.value = (sellingPrice - privateDebt);
  
}
