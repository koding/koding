var Diff, DiffScriptFactory;

Diff = require("./lib/diff");

DiffScriptFactory = (function() {

  function DiffScriptFactory() {
    this.src = "";
  }

  DiffScriptFactory.prototype.createScript = function(dest) {
    var any_change, any_common, res, src;
    src = this.src;
    this.src = dest;
    if (!(dest != null)) return 'n';
    if (!src.length) return "R" + dest;
    res = "";
    any_change = false;
    any_common = false;
    Diff.parseDiff(src, dest, function(type, str) {
      switch (type) {
        case 0:
          res += "d" + str.length + ":";
          return any_change = true;
        case 1:
          res += "i" + str.length + ":" + str;
          return any_change = true;
        case 2:
          res += "k" + str.length + ":";
          return any_common = true;
      }
    });
    if (!any_change) {
      if (!any_common) {
        return "R" + dest;
      } else {
        return "n";
      }
    }
    return res;
  };

  DiffScriptFactory.prototype.reset = function() {
    return this.src = "";
  };

  return DiffScriptFactory;

})();

module.exports = DiffScriptFactory;
