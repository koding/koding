// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');

var dn = require('../dn');
var errors = require('../errors');
var logStub = require('../log_stub');

var getTransformer = require('./transform').getTransformer;


function transformFilter(schema, filter) {
  assert.ok(schema);
  assert.ok(filter);

  var attributes = schema.attributes;

  switch (filter.type) {
  case 'equal':
  case 'approx':
  case 'ge':
  case 'le':
    if (!attributes[filter.attribute.toLowerCase()])
      throw new errors.NoSuchAttributeError(filter.attribute);

    var transform = getTransformer(schema, filter.attribute);
    if (transform)
      filter.value = transform(filter.value) || filter.value;

    break;

  case 'substring':
  case 'present':
    if (!attributes[filter.attribute.toLowerCase()])
      throw new errors.NoSuchAttributeError(filter.attribute);

    break;

  case 'and':
  case 'or':
    for (var i = 0; i < filter.filters.length; i++)
      filter.filters[i] = transformFilter(schema, filter.filters[i]);

    break;

  case 'not':
    filter.filter = trasnformFilter(schema, filter.filter);
  }

  return filter;
}



function createSearchHandler(options) {
  if (!options || typeof(options) !== 'object')
    throw new TypeError('options (object) required');
  if (!options.schema || typeof(options.schema) !== 'object')
    throw new TypeError('options.schema (object) required');

  var log4js = options.log4js || logStub;
  var log = log4js.getLogger('SchemaSearchHandler');
  var schema = options.schema;

  var CVErr = errors.ConstraintViolationError;
  var NSAErr = errors.NoSuchAttributeError;
  var OCVErr = errors.ObjectclassViolationError;

  return function schemaSearchHandler(req, res, next) {
    if (log.isDebugEnabled())
      log.debug('%s running %j against schema', req.logId, req.filter);

    try {
      req.filter = transformFilter(schema, req.filter);
    } catch (e) {
      if (log.isDebugEnabled())
        log.debug('%s error transforming filter: %s', req.logId, e.stack);
      return next(e);
    }

    return next();
  }
}



module.exports = createSearchHandler;
