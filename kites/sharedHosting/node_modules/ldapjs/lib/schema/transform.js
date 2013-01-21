// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');

var dn = require('../dn');



///--- API

function _getTransformer(syntax) {
  assert.ok(syntax);

  // TODO size enforcement
  if (/\}$/.test(syntax))
    syntax = syntax.replace(/\{.+\}$/, '');

  switch (syntax) {
  case '1.3.6.1.4.1.1466.115.121.1.27': // int
  case '1.3.6.1.4.1.1466.115.121.1.36': // numeric string
    return function(value) {
      return parseInt(value, 10);
    };

  case '1.3.6.1.4.1.1466.115.121.1.7':  // boolean
    return function(value) {
      return /^true$/i.test(value);
    };

  case '1.3.6.1.4.1.1466.115.121.1.5':  // binary
    return function(value) {
      return new Buffer(value).toString('base64');
    };

  case '1.3.6.1.4.1.1466.115.121.1.12':  // dn syntax
    return function(value) {
      return dn.parse(value).toString();
    };
  default:
    // noop
  }

  return null;

}


function getTransformer(schema, type) {
  assert.ok(schema);
  assert.ok(type);

  if (!schema.attributes[type] || !schema.attributes[type].syntax)
    return null;

  return _getTransformer(schema.attributes[type].syntax);
}


function transformValue(schema, type, value) {
  assert.ok(schema);
  assert.ok(type);
  assert.ok(value);

  if (!schema.attributes[type] || !schema.attributes[type].syntax)
    return value;

  var transformer = _getTransformer(schema.attributes[type].syntax);

  return transformer ? transformer(value) : null;
}


function transformObject(schema, attributes, keys) {
  assert.ok(schema);
  assert.ok(attributes);

  if (!keys)
    keys = Object.keys(attributes);

  var xformed = false;

  keys.forEach(function(k) {
    k = k.toLowerCase();

    var transform = _getTransformer(schema.attributes[k].syntax);
    if (transform) {
      xformed = true;

      var vals = attributes[k];
      console.log('%s -> %j', k, vals);
      for (var i = 0; i < vals.length; i++)
        vals[i] = transform(vals[i]);
    }
  });

  return xformed;
}




module.exports = {

  transformObject: transformObject,
  transformValue: transformValue,
  getTransformer: getTransformer
};



    // var syntax = schema.attributes[k].syntax;
    // if (/\}$/.test(syntax))
    //   syntax = syntax.replace(/\{.+\}$/, '');

    // switch (syntax) {
    // case '1.3.6.1.4.1.1466.115.121.1.27': // int
    // case '1.3.6.1.4.1.1466.115.121.1.36': // numeric string
    //   for (j = 0; j < attr.length; j++)
    //     attr[j] = parseInt(attr[j], 10);
    //   xformed = true;
    //   break;
    // case '1.3.6.1.4.1.1466.115.121.1.7':  // boolean
    //   for (j = 0; j < attr.length; j++)
    //     attr[j] = /^true$/i.test(attr[j]);
    //   xformed = true;
    //   break;
    // case '1.3.6.1.4.1.1466.115.121.1.5':  // binary
    //   for (j = 0; j < attr.length; j++)
    //     attr[j] = new Buffer(attr[j]).toString('base64');
    //   xformed = true;
    //   break;
    // case '1.3.6.1.4.1.1466.115.121.1.12':  // dn syntax
    //   for (j = 0; j < attr.length; j++)
    //     attr[j] = dn.parse(attr[j]).toString();
    //   xformed = true;
    //   break;
    // default:
    //   // noop
    // }
