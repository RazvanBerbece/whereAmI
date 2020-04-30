/* JS Helper Functions */

/* 
	Checks if the number can be parsed as float,
	For input sanity check purposes.
*/
function isFloat(input) {
  
  var result = parseFloat(input);

  if ((isNaN(result)) == false) {
    return true;
  }
  
  return false;
}

