var exports;

exports = {};

exports.pty = (require("./lib/terminal")).Terminal;

exports.htmlify = require("./lib/htmlify");

exports.DiffScriptFactory = require("./DiffScriptFactory");

exports.DiffScript = require("./DiffScript");

module.exports = exports;
