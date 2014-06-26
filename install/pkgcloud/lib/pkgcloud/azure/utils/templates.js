/*
 * templates.js: template loader
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var fs = require('fs');
var _ = require('underscore');

exports.load = function (path, callback) {
  fs.readFile(path, 'utf8', function (err, data) {
    callback(err, data);
  });
};

exports.compile = function (path, params, callback) {
  fs.readFile(path, 'utf8', function (err, data) {
    if (err) {
      callback(err);
    } else {
      callback(null, _.template(data, params));
    }
  });
};


