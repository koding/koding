'use strict';

/* 3rd party module */
var lodash = require('lodash');

/*jslint bitwise:true*/

/**
 * Simple object merger
 * TODO: remove it by refactoring the client
 * 
 * @param {Object} obj1
 * @param {Object} obj2
 * @returns {Object}
 */
var merge = function (obj1, obj2) {
	var obj3 = {};
	lodash.merge(obj3, obj1, obj2);
	return obj3;
};
exports.merge = merge;

/**
 * Returns the absolute integer value of the input. Avoids the NaN crap.
 * 
 * @param value
 * @returns {Number}
 */
var absInt = function (value) {
	return Math.abs(parseInt(value, 10) | 0);
};
exports.absInt = absInt;

/**
 * Sorts the keys of an object
 * 
 * @param {String} obj
 * @returns {Object}
 */
var sortObject = function (obj) {
	var key, sorted = {}, a = [];
	
	a = Object.keys(obj).sort();
	
	for (key = 0; key < a.length; key++) {
		sorted[a[key]] = obj[a[key]];
	}
	
	return sorted;
};
exports.sortObject = sortObject;

/**
 * [DEPRECATED] Escapes a S3 path
 * 
 * @param {String} path
 * @returns {String}
 */
var escapePath = function (path) {
	console.error('Warning: aws2js/S3 use of .escapePath() is deprecated.  Use JavaScript\'s encodeURI() instead.');
	return encodeURI(path);
};
exports.escapePath = escapePath;
