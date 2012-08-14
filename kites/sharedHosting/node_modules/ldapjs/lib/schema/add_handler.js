// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');

var dn = require('../dn');
var errors = require('../errors');
var logStub = require('../log_stub');

var getTransformer = require('./transform').getTransformer;



function createAddHandler(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');
  if (!options.schema || typeof(options.schema) !== 'object')
    throw new TypeError('options.schema (object) required');

  var log4js = options.log4js || logStub;
  var log = log4js.getLogger('SchemaAddHandler');
  var schema = options.schema;

  if (log.isDebugEnabled())
    log.debug('Creating add schema handler with: %s',
              JSON.stringify(options.schema, null, 2));

  var CVErr = errors.ConstraintViolationError;
  var NSAErr = errors.NoSuchAttributeError;
  var OCVErr = errors.ObjectclassViolationError;

  return function schemaAddHandler(req, res, next) {
    var allowed = [];
    var attributes = req.toObject().attributes;
    var attrNames = Object.keys(attributes);
    var i;
    var j;
    var k;
    var key;

    if (log.isDebugEnabled())
      log.debug('%s running %j against schema', req.logId, attributes);

    if (!attributes.objectclass)
      return next(new OCVErr('no objectclass'));

    for (i = 0; i < attributes.objectclass.length; i++) {
      var oc = attributes.objectclass[i].toLowerCase();
      if (!schema.objectclasses[oc])
        return next(new NSAErr(oc + ' is not a known objectClass'));

      // We can check required attributes right here in line. Mays we have to
      // get the complete set of though. Also, to make checking much simpler,
      // we just push the musts into the may list.
      var must = schema.objectclasses[oc].must;
      for (j = 0; j < must.length; j++) {
        if (attrNames.indexOf(must[j]) === -1)
          return next(new OCVErr(must[j] + ' is a required attribute'));
        if (allowed.indexOf(must[j]) === -1)
          allowed.push(must[j]);
      }

      schema.objectclasses[oc].may.forEach(function(attr) {
        if (allowed.indexOf(attr) === -1)
          allowed.push(attr);
      });
    }

    // Now check that the entry's attributes are in the allowed list, and go
    // ahead and transform the values as appropriate
    for (i = 0; i < attrNames.length; i++) {
      key = attrNames[i];
      if (allowed.indexOf(key) === -1)
        return next(new OCVErr(key + ' is not valid for the objectClasses ' +
                               attributes.objectclass.join()));

      var transform = getTransformer(schema, key);
      if (transform) {
        for (j = 0; j < attributes[key].length; j++) {
          try {
            attributes[key][j] = transform(attributes[key][j]);
          } catch (e) {
            log.debug('%s Error parsing %s: %s', req.logId, k,
                      attributes[key][j],
                      e.stack);
            return next(new CVErr(attrNames[i]));
          }
        }
        for (j = 0; j < req.attributes.length; j++) {
          if (req.attributes[j].type === key) {
            req.attributes[j].vals = attributes[key];
            break;
          }
        }
      }
    }

    return next();
  };
}

module.exports = createAddHandler;

    // Now we have a modified attributes object we want to update
    // "transparently" in the request.
    // if (xformedValues) {
    //   attrNames.forEach(function(k) {
    //     for (var i = 0; i < req.attributes.length; i++) {
    //       if (req.attributes[i].type === k) {
    //         req.attributes[i].vals = attributes[k];
    //         return;
    //       }
    //     }
    //   });
    // }

