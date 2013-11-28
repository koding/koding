define(function(require, exports, module) {

exports.isDark = true;
exports.cssClass = "ace-koding";
exports.cssText = require("../requirejs/text!./koding.css");

var dom = require("../lib/dom");
dom.importCssString(exports.cssText, exports.cssClass);
});
