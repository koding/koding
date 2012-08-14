// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');

var dn = require('../dn');
var errors = require('../errors');
var logStub = require('../log_stub');

var getTransformer = require('./transform').getTransformer;



function createModifyHandler(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');
  if (!options.schema || typeof(options.schema) !== 'object')
    throw new TypeError('options.schema (object) required');
  // TODO add a callback mechanism here so objectclass constraints can be
  // enforced

  var log4js = options.log4js || logStub;
  var log = log4js.getLogger('SchemaModifyHandler');
  var schema = options.schema;

  var CVErr = errors.ConstraintViolationError;
  var NSAErr = errors.NoSuchAttributeError;
  var OCVErr = errors.ObjectclassViolationError;

  return function schemaModifyHandler(req, res, next) {
    if (log.isDebugEnabled())
      log.debug('%s running %j against schema', req.logId, req.changes);

    for (var i = 0; i < req.changes.length; i++) {
      var mod = req.changes[i].modification;
      var attribute = schema.attributes[mod.type];
      if (!attribute)
        return next(new NSAErr(mod.type));

      if (!mod.vals || !mod.vals.length)
        continue;

      var transform = getTransformer(schema, mod.type);
      if (transform) {
        for (var j = 0; j < mod.vals.length; j++) {
          try {
            mod.vals[j] = transform(mod.vals[j]);
          } catch (e) {
            log.debug('%s Error parsing %s: %s', req.logId, mod.vals[j],
                      e.stack);
            return next(new CVErr(mod.type + ': ' + mod.vals[j]));
          }
        }
      }
    }
    return next();
  }
}

module.exports = createModifyHandler;
