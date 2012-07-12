var DiffScript, DiffScriptFactory, createRandomString, diffFactory, diffParser, run_time, testDiff, timer,
  _this = this;

DiffScript = require("./DiffScript");

DiffScriptFactory = require("./DiffScriptFactory");

createRandomString = function(len) {
  var charSet, pos, randomChar, randomString;
  charSet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  randomString = '';
  pos = 0;
  while (pos < len) {
    randomChar = Math.floor(Math.random() * charSet.length);
    randomString += charSet.substring(randomChar, randomChar + 1);
    pos++;
  }
  return randomString;
};

diffFactory = new DiffScriptFactory;

diffParser = new DiffScript;

run_time = 0;

testDiff = function() {
  var diff, reproduced_string, string;
  string = "string <random length=10 >" + createRandomString(10) + "</random>";
  console.log("original string: " + string);
  diff = diffFactory.createScript(string);
  console.log("diff script : " + diff);
  reproduced_string = diffParser.dispatch(diff);
  console.log("reproduced string : " + reproduced_string);
  if (reproduced_string !== string) throw "diff script test failed";
  run_time++;
  if (run_time > 10) return process.exit();
};

timer = setInterval(testDiff, 2);
