/*
 * util.js
 *  - utility helper functions for querystring module
 *
 * Chad Etzel
 *
 * Copyright (c) 2009, Yahoo! Inc. and Chad Etzel
 * BSD License (see LICENSE.md for info)
 *
 */
exports.is = is;
exports.isNull = isNull;
exports.isUndefined = isUndefined;
exports.isString = isString;
exports.isNumber = isNumber;
exports.isBoolean = isBoolean;
exports.isArray = isArray;
exports.isObject = isObject;


function is (type, obj) {
  return Object.prototype.toString.call(obj) === '[object '+type+']';
}

function isArray (obj) {
  return is("Array", obj);
}

function isObject (obj) {
  return is("Object", obj);
}

function isString (obj) {
  return is("String", obj);
}

function isNumber (obj) {
  return is("Number", obj);
}

function isBoolean (obj) {
  return is("Boolean", obj);
}

function isNull (obj) {
  return typeof obj === "object" && !obj;
}

function isUndefined (obj) {
  return typeof obj === "undefined";
}
