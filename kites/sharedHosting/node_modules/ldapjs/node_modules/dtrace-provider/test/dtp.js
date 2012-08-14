var d = require('../dtrace-provider');
var dtp = d.createDTraceProvider("nodeapp");
dtp.addProbe("probe1", "int", "int", "int", "int", "int", "int");
dtp.addProbe("probe2", "char *", "char *", "char *", "char *", "char *", "char *");
dtp.enable();
dtp.fire("probe1", function(p) { return [1, 2, 3, 4, 5, 6]; });
dtp.fire("probe2", function(p) { return ["hello, dtrace", "foo", "bar", "baz", "fred", "barney"]; });

