var DiffScript;

DiffScript = (function() {

  function DiffScript() {
    this.source = "";
  }

  DiffScript.prototype.dispatch = function(scr) {
    var cmd, cursor, i, m, num, result;
    if (scr.charAt(0) === "n") return this.source;
    if (scr.charAt(0) === "R") {
      this.source = scr.substr(1);
      return this.source;
    }
    i = 0;
    cursor = 0;
    result = "";
    while (i < scr.length) {
      cmd = scr.charAt(i);
      i++;
      m = scr.indexOf(":", i);
      num = Number(scr.substr(i, m - i));
      i = m + 1;
      switch (cmd) {
        case "d":
          /*
                      just forward the source cursor
          */
          cursor += num;
          break;
        case "i":
          result += scr.substr(i, num);
          i += num;
          break;
        case "k":
          result += this.source.substr(cursor, num);
          cursor += num;
      }
    }
    this.source = result;
    return result;
  };

  return DiffScript;

})();

if (!(typeof window !== "undefined" && window !== null)) {
  module.exports = DiffScript;
}
