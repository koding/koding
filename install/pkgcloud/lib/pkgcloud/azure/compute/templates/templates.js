/*
 * templates.js: Implementation template loader
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var fs = require('fs');
var PATH = require('path');
var _ = require('underscore');

exports.loadSync = function (name) {
  var path = PATH.join(__dirname, name);
  return fs.readFileSync(path, 'utf8');
};

exports.compileSync = function (template, params) {
  return _.template(template, params);
};

exports.load = function (name, callback) {
  var path = PATH.join(__dirname, name);
  fs.readFile(path, 'utf8', function (err, data) {
    callback(err, data);
  });
};

exports.compile = function (name, params, callback) {
  var path = PATH.join(__dirname, name);
  fs.readFile(path, 'utf8', function (err, data) {
    callback(err, _.template(data, params));
  });
};


