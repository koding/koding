/*jshint node:true es5:true strict:true laxcomma:true laxbreak:true*/
(function () {
  "use strict";

  var fs = require('fs')
    , util = require('util')
    , fsCopy = require('./fs.copy')
    ;

  function noop() {}

  function move(src, dst, cb) {
    function copyIfFailed(err) {
      if (!err) {
        return cb(null);
      }
      fsCopy(src, dst, function(err) {
        if (!err) {
          // TODO 
          // should we revert the copy if the unlink fails?
          fs.unlink(src, cb);
        } else {
          cb(err);
        }
      });
    }

    cb = cb || noop;
    fs.stat(dst, function (err) {
      if (!err) {
        return cb(new Error("File " + dst + " exists."));
      }
      fs.rename(src, dst, copyIfFailed);
    });
  }

  module.exports = move;
}());
