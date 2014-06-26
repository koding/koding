/*
 * model.js: Base model from which all pkgcloud models inherit from
 *
 * (C) 2011 Nodejitsu Inc.
 *
 */

var events = require('eventemitter2'),
    utile = require('utile');

var Model = exports.Model = function (client, details) {
  events.EventEmitter2.call(this, { delimiter: '::', wildcard: true });
  this.client = client;

  if (details) {
    this._setProperties(details);
  }
};

utile.inherits(Model, events.EventEmitter2);

// ### function setWait (attributes, interval, callback)
//
// Continually polls resource and checks the
// results against the attributes parameter.
// When the attributes match the callback will be fired
//
// e.g. server.setWait({ status: 'RUNNING' }, 5000, function (err, resource) {
//        console.log('status is now running');
//      });
//
// #### @attributes  {Object|Function}  Attributes to match. Optionally provide a matching function
// ####    @*        {*}       **Optional** Key and expected value
// #### @interval    {Integer} Time between pools in ms.
// #### @timeLimit   {Integer} **Optional** Max time to spend executing
// #### @callback {Function} f(err, resource).
function setWait(attributes, interval, timeLimit, callback) {
  if (typeof timeLimit === 'function') {
    callback  = timeLimit;
    timeLimit = null;
  }

  var self  = this,
      start = Date.now(),
      fired = false,
      equalCheckId,
      current;

  equalCheckId = setInterval(function () {
    self.refresh(function (err, resource) {

      if (timeLimit) {
        current = Date.now();
        if (current - start > timeLimit) {
          clearInterval(equalCheckId);
          if (!fired) {
            fired = true;
            callback(err, resource);
            return;
          }
        }
      }

      if (err) {
        return;
      } // Ignore errors

      var equal = true,
          keys  = Object.keys(attributes);

      if (typeof attributes === 'function') {
        equal = attributes(resource);
      }
      else {
        for (var i = 0; i < keys.length; i++) {
          if (attributes[keys[i]] !== resource[keys[i]]) {
            equal = false;
            break;
          }
        }
      }

      if (equal) {
        clearInterval(equalCheckId);
        callback(null, resource);
      }
    });
  }, interval);

  return equalCheckId;
}

// clear the interval
function clear(intervalId) {
  clearInterval(intervalId);
}

Model.prototype.until     = setWait;
Model.prototype.setWait   = setWait;
Model.prototype.clearWait = clear;