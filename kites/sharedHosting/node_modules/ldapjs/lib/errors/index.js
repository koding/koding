// Copyright 2011 Mark Cavage, Inc.  All rights reserved.

var util = require('util');

var LDAPResult = require('../messages').LDAPResult;


///--- Globals

var CODES = {
  LDAP_SUCCESS: 0,
  LDAP_OPERATIONS_ERROR: 1,
  LDAP_PROTOCOL_ERROR: 2,
  LDAP_TIME_LIMIT_EXCEEDED: 3,
  LDAP_SIZE_LIMIT_EXCEEDED: 4,
  LDAP_COMPARE_FALSE: 5,
  LDAP_COMPARE_TRUE: 6,
  LDAP_AUTH_METHOD_NOT_SUPPORTED: 7,
  LDAP_STRONG_AUTH_REQUIRED: 8,
  LDAP_REFERRAL: 10,
  LDAP_ADMIN_LIMIT_EXCEEDED: 11,
  LDAP_UNAVAILABLE_CRITICAL_EXTENSION: 12,
  LDAP_CONFIDENTIALITY_REQUIRED: 13,
  LDAP_SASL_BIND_IN_PROGRESS: 14,
  LDAP_NO_SUCH_ATTRIBUTE: 16,
  LDAP_UNDEFINED_ATTRIBUTE_TYPE: 17,
  LDAP_INAPPROPRIATE_MATCHING: 18,
  LDAP_CONSTRAINT_VIOLATION: 19,
  LDAP_ATTRIBUTE_OR_VALUE_EXISTS: 20,
  LDAP_INVALID_ATTRIBUTE_SYNTAX: 21,
  LDAP_NO_SUCH_OBJECT: 32,
  LDAP_ALIAS_PROBLEM: 33,
  LDAP_INVALID_DN_SYNTAX: 34,
  LDAP_ALIAS_DEREF_PROBLEM: 36,
  LDAP_INAPPROPRIATE_AUTHENTICATION: 48,
  LDAP_INVALID_CREDENTIALS: 49,
  LDAP_INSUFFICIENT_ACCESS_RIGHTS: 50,
  LDAP_BUSY: 51,
  LDAP_UNAVAILABLE: 52,
  LDAP_UNWILLING_TO_PERFORM: 53,
  LDAP_LOOP_DETECT: 54,
  LDAP_NAMING_VIOLATION: 64,
  LDAP_OBJECTCLASS_VIOLATION: 65,
  LDAP_NOT_ALLOWED_ON_NON_LEAF: 66,
  LDAP_NOT_ALLOWED_ON_RDN: 67,
  LDAP_ENTRY_ALREADY_EXISTS: 68,
  LDAP_OBJECTCLASS_MODS_PROHIBITED: 69,
  LDAP_AFFECTS_MULTIPLE_DSAS: 71,
  LDAP_OTHER: 80
};

var ERRORS = [];



///--- Error Base class

function LDAPError(errorName, errorCode, msg, dn, caller) {
  if (Error.captureStackTrace)
    Error.captureStackTrace(this, caller || LDAPError);

  this.__defineGetter__('dn', function() {
    return (dn ? (dn.toString() || '') : '');
  });
  this.__defineGetter__('code', function() {
    return errorCode;
  });
  this.__defineGetter__('name', function() {
    return errorName;
  });
  this.__defineGetter__('message', function() {
    return msg || errorName;
  });
}
util.inherits(LDAPError, Error);



///--- Exported API
// Some whacky games here to make sure all the codes are exported

module.exports = {};
module.exports.LDAPError = LDAPError;

Object.keys(CODES).forEach(function(code) {
  module.exports[code] = CODES[code];
  if (code === 'LDAP_SUCCESS')
    return;

  var err = '';
  var msg = '';
  var pieces = code.split('_').slice(1);
  for (var i = 0; i < pieces.length; i++) {
    var lc = pieces[i].toLowerCase();
    var key = lc.charAt(0).toUpperCase() + lc.slice(1);
    err += key;
    msg += key + ((i + 1) < pieces.length ? ' ' : '');
  }

  if (!/\w+Error$/.test(err))
    err += 'Error';

  // At this point LDAP_OPERATIONS_ERROR is now OperationsError in $err
  // and 'Operations Error' in $msg
  module.exports[err] = function(message, dn, caller) {
    LDAPError.call(this,
                   err,
                   CODES[code],
                   message || msg,
                   dn || null,
                   caller || module.exports[err]);
  }
  module.exports[err].constructor = module.exports[err];
  util.inherits(module.exports[err], LDAPError);

  ERRORS[CODES[code]] = {
    err: err,
    message: msg
  };
});


module.exports.getError = function(res) {
  if (!(res instanceof LDAPResult))
    throw new TypeError('res (LDAPResult) required');

  var errObj = ERRORS[res.status];
  var E = module.exports[errObj.err];
  return new E(res.errorMessage || errObj.message,
               res.matchedDN || null,
               module.exports.getError);
};


module.exports.getMessage = function(code) {
  if (typeof(code) !== 'number')
    throw new TypeError('code (number) required');

  var errObj = ERRORS[res.status];
  return (errObj && errObj.message ? errObj.message : '');
};
