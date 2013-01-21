// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var assert = require('assert');
var fs = require('fs');

var dn = require('../dn');
var errors = require('../errors');
var logStub = require('../log_stub');



//// Attribute BNF
//
// AttributeTypeDescription = "(" whsp
//       numericoid whsp              ; AttributeType identifier
//     [ "NAME" qdescrs ]             ; name used in AttributeType
//     [ "DESC" qdstring ]            ; description
//     [ "OBSOLETE" whsp ]
//     [ "SUP" woid ]                 ; derived from this other
//                                    ; AttributeType
//     [ "EQUALITY" woid              ; Matching Rule name
//     [ "ORDERING" woid              ; Matching Rule name
//     [ "SUBSTR" woid ]              ; Matching Rule name
//     [ "SYNTAX" whsp noidlen whsp ] ; Syntax OID
//     [ "SINGLE-VALUE" whsp ]        ; default multi-valued
//     [ "COLLECTIVE" whsp ]          ; default not collective
//     [ "NO-USER-MODIFICATION" whsp ]; default user modifiable
//     [ "USAGE" whsp AttributeUsage ]; default userApplications
//     whsp ")"
//
// AttributeUsage =
//     "userApplications"     /
//     "directoryOperation"   /
//     "distributedOperation" / ; DSA-shared
//     "dSAOperation"          ; DSA-specific, value depends on server

/// Objectclass BNF
//
// ObjectClassDescription = "(" whsp
//                 numericoid whsp      ; ObjectClass identifier
//                 [ "NAME" qdescrs ]
//                 [ "DESC" qdstring ]
//                 [ "OBSOLETE" whsp ]
//                 [ "SUP" oids ]       ; Superior ObjectClasses
//                 [ ( "ABSTRACT" / "STRUCTURAL" / "AUXILIARY" ) whsp ]
//                         ; default structural
//                 [ "MUST" oids ]      ; AttributeTypes
//                 [ "MAY" oids ]       ; AttributeTypes
//                 whsp ")"

// This is some fugly code, and really not that robust, but LDAP schema
// is a pita with its optional ('s. So, whatever, it's good enough for our
// purposes (namely, dropping in the OpenLDAP schema). This took me a little
// over an hour to write, so there you go ;)

function parse(data) {
  if (!data || typeof(data) !== 'string')
    throw new TypeError('data (string) required');

  var lines = [];
  data.split('\n').forEach(function(l) {
    if (/^#/.test(l) ||
        /^objectidentifier/i.test(l) ||
        !l.length)
      return;

    lines.push(l);
  });

  var attr;
  var oc;
  var syntax;
  var attributes = [];
  var objectclasses = [];
  var depth = 0;
  lines.join('\n').split(/\s+/).forEach(function(w) {
    if (attr) {
      if (w === '(') {
        depth++;
      } else if (w === ')') {
        if (--depth === 0) {
          if (attr._skip)
            delete attr._skip;

          attributes.push(attr);
          attr = null;
        }
        return;
      } else if (!attr.oid) {
        attr.oid = w;
      } else if (w === 'NAME') {
        attr._names = [];
      } else if (w === 'DESC') {
        attr._desc = '';
      } else if (w === 'OBSOLETE') {
        attr.obsolete = true;
      } else if (w === 'SUP') {
        attr._sup = true;
      } else if (attr._sup) {
        attr.sup = w;
        delete attr._sup;
      } else if (w === 'EQUALITY') {
        attr._equality = true;
      } else if (w === 'ORDERING') {
        attr._ordering = true;
      } else if (w === 'SUBSTR') {
        attr._substr = true;
      } else if (w === 'SYNTAX') {
        attr._syntax = true;
      } else if (w === 'SINGLE-VALUE') {
        attr.singleValue = true;
      } else if (w === 'COLLECTIVE') {
        attr.collective = true;
      } else if (w === 'NO-USER-MODIFICATION') {
        attr.noUserModification = true;
      } else if (w === 'USAGE') {
        attr._usage = true;
      } else if (/^X-/.test(w)) {
        attr._skip = true;
      } else if (attr._skip) {
        // noop
      } else if (attr._usage) {
        attr.usage = w;
        delete attr._usage;
      } else if (attr._syntax) {
        attr.syntax = w;
        delete attr._syntax;
      } else if (attr._substr) {
        attr.substr = w;
        delete attr._substr;
      } else if (attr._ordering) {
        attr.ordering = w;
        delete attr._ordering;
      } else if (attr._equality) {
        attr.equality = w;
        delete attr._equality;
      } else if (attr._desc !== undefined) {
        attr._desc += w.replace(/\'/g, '');
        if (/\'$/.test(w)) {
          attr.desc = attr._desc;
          delete attr._desc;
        } else {
          attr._desc += ' ';
        }
      } else if (attr._names) {
        attr._names.push(w.replace(/\'/g, '').toLowerCase());
      }
      return;
    }

    if (oc) {
      if (w === '(') {
        depth++;
      } else if (w === ')') {
        if (--depth === 0) {
          objectclasses.push(oc);
          oc = null;
        }
        return;
      } else if (w === '$') {
        return;
      } else if (!oc.oid) {
        oc.oid = w;
      } else if (w === 'NAME') {
        oc._names = [];
      } else if (w === 'DESC') {
        oc._desc = '';
      } else if (w === 'OBSOLETE') {
        oc.obsolete = true;
      } else if (w === 'SUP') {
        oc._sup = [];
      } else if (w === 'ABSTRACT') {
        oc['abstract'] = true;
      } else if (w === 'AUXILIARY') {
        oc.auxiliary = true;
      } else if (w === 'STRUCTURAL') {
        oc.structural = true;
      } else if (w === 'MUST') {
        oc._must = [];
      } else if (w === 'MAY') {
        oc._may = [];
      } else if (oc._may) {
        oc._may.push(w.toLowerCase());
      } else if (oc._must) {
        oc._must.push(w.toLowerCase());
      } else if (oc._sup) {
        oc._sup.push(w.replace(/\'/g, '').toLowerCase());
      } else if (oc._desc !== undefined) {
        oc._desc += w.replace(/\'/g, '');
        if (/\'$/.test(w)) {
          oc.desc = oc._desc;
          delete oc._desc;
        } else {
          oc._desc += ' ';
        }
      } else if (oc._names) {
        oc._names.push(w.replace(/\'/g, '').toLowerCase());
      }

      return;
    }

    // Throw this away for now.
    if (syntax) {
      if (w === '(') {
        depth++;
      } else if (w === ')') {
        if (--depth === 0) {
          syntax = false;
        }
      }
      return;
    }

    if (/^attributetype/i.test(w)) {
      attr = {};
    } else if (/^objectclass/i.test(w)) {
      oc = {};
    } else if (/^ldapsyntax/i.test(w)) {
      syntax = true;
    } else if (!w) {
      // noop
    } else {
      throw new Error('Invalid token ' + w + ' in file ' + file);
    }
  });

  // cleanup all the temporary arrays
  var i;
  for (i = 0; i < attributes.length; i++) {
    if (!attributes[i]._names)
      continue;

    attributes[i].names = attributes[i]._names;
    delete attributes[i]._names;
  }
  for (i = 0; i < objectclasses.length; i++) {
    oc = objectclasses[i];
    if (oc._names) {
      oc.names = oc._names;
      delete oc._names;
    } else {
      oc.names = [];
    }
    if (oc._sup) {
      oc.sup = oc._sup;
      delete oc._sup;
    } else {
      oc.sup = [];
    }
    if (oc._must) {
      oc.must = oc._must;
      delete oc._must;
    } else {
      oc.must = [];
    }
    if (oc._may) {
      oc.may = oc._may;
      delete oc._may;
    } else {
      oc.may = [];
    }
  }

  var _attributes = {};
  var _objectclasses = {};
  attributes.forEach(function(a) {
    for (var i = 0; i < a.names.length; i++) {
      a.names[i] = a.names[i].toLowerCase();
      _attributes[a.names[i]] = a;
    }
  });

  objectclasses.forEach(function(oc) {
    for (var i = 0; i < oc.names.length; i++) {
      oc.names[i] = oc.names[i].toLowerCase();
      _objectclasses[oc.names[i]] = oc;
    }
  });

  return {
    attributes: _attributes,
    objectclasses: _objectclasses
  };
}


function parseFile(file, callback) {
  if (!file || typeof(file) !== 'string')
    throw new TypeError('file (string) required');
  if (!callback || typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  fs.readFile(file, 'utf8', function(err, data) {
    if (err)
      return callback(new errors.OperationsError(err.message));

    try {
      return callback(null, parse(data));
    } catch (e) {
      return callback(new errors.OperationsError(e.message));
    }
  });
}


function _merge(child, parent) {
  Object.keys(parent).forEach(function(k) {
    if (Array.isArray(parent[k])) {
      if (k === 'names' || k === 'sup')
        return;

      if (!child[k])
        child[k] = [];

      parent[k].forEach(function(v) {
        if (child[k].indexOf(v) === -1)
          child[k].push(v);
      });
    } else if (!child[k]) {
      child[k] = parent[k];
    }
  });

  return child;
}


function compile(attributes, objectclasses) {
  assert.ok(attributes);
  assert.ok(objectclasses);

  var _attributes = {};
  var _objectclasses = {};

  Object.keys(attributes).forEach(function(k) {
    _attributes[k] = attributes[k];

    var sup;
    if (attributes[k].sup && (sup = attributes[attributes[k].sup]))
      _attributes[k] = _merge(_attributes[k], sup);

    _attributes[k].names.sort();
  });

  Object.keys(objectclasses).forEach(function(k) {
    _objectclasses[k] = objectclasses[k];
    var sup;
    if (objectclasses[k].sup && (sup = objectclasses[objectclasses[k].sup]))
      _objectclasses[k] = _merge(_objectclasses[k], sup);

    _objectclasses[k].names.sort();
    _objectclasses[k].sup.sort();
    _objectclasses[k].must.sort();
    _objectclasses[k].may.sort();
  });

  return {
    attributes: _attributes,
    objectclasses: _objectclasses
  };
}



/**
 * Loads all the `.schema` files in a directory, and parses them.
 *
 * This method returns the set of schema from all files, and the "last one"
 * wins, so don't do something stupid like have the same attribute defined
 * N times with varying definitions.
 *
 * @param {String} directory the directory of *.schema files to load.
 * @param {Function} callback of the form f(err, attributes, objectclasses).
 * @throws {TypeEror} on bad input.
 */
function load(directory, callback) {
  if (!directory || typeof(directory) !== 'string')
    throw new TypeError('directory (string) required');
  if (!callback || typeof(callback) !== 'function')
    throw new TypeError('callback (function) required');

  fs.readdir(directory, function(err, files) {
    if (err)
      return callback(new errors.OperationsError(err.message));

    var finished = 0;
    var attributes = {};
    var objectclasses = {};
    files.forEach(function(f) {
      if (!/\.schema$/.test(f)) {
        ++finished;
        return;
      }

      f = directory + '/' + f;
      parseFile(f, function(err, schema) {
        var cb = callback;
        if (err) {
          callback = null;
          if (cb)
            return cb(new errors.OperationsError(err.message));

          return;
        }

        Object.keys(schema.attributes).forEach(function(a) {
          attributes[a] = schema.attributes[a];
        });
        Object.keys(schema.objectclasses).forEach(function(oc) {
          objectclasses[oc] = schema.objectclasses[oc];
        });

        if (++finished === files.length) {
          if (cb) {
            schema = compile(attributes, objectclasses);
            return cb(null, schema);
          }
        }
      });
    });
  });
}



///--- Exported API

module.exports = {

  load: load,
  parse: parse,
  parseFile: parseFile


};

