'use strict';

/* Load the dependencies */
var dependencies = require('../config/dependencies.js');
var xmlDep = require(dependencies.xml);
var mimeDep = require(dependencies.mime);

/* core modules */
var fs = require('fs');
var u = require('url');
var p = require('path');
var https = require('https');
var crypto = require('crypto');
var qs = require('querystring');
var Stream = require('stream').Stream;
var EventEmitter = require('events').EventEmitter;

/* 3rd party module */
var lodash = require('lodash');

/* the internally used modules */
require('./Buffer.toByteArray.js');
var cfg = require('../config/aws.js');
var tools = require('./tools.js');

/**
 * Checks the config for the minimally allowable setup
 * 
 * @param {Object} config
 * @param {Function} callback
 * @returns {Boolean} bool
 */
var checkConfig = function (config) {
	if ( ! config.accessKeyId || ! config.secretAccessKey) {
		throw new Error('You must set the AWS credentials: accessKeyId + secretAccessKey');
	}
	if (config.prefix === 'dynamodb' && ! config.sessionToken) {
		throw new Error('You must pass a sessionToken argument along with the AWS credentials.');
	}
};
exports.checkConfig = checkConfig;

/**
 * Filters the byte range for a ReadStream
 * 
 * @param {Object} range
 * @param {Function} callback
 * @returns {Object}
 */
var filterByteRange = function (range, length, callback) {
	var err;
	
	if ( ! isNaN(Number(range.start))) {
		if (range.start < 0) {
			range.start = 0;
		}
		if (length) {
			if (range.start >= length) {
				err = new Error('The start value of a byte range can\'t be more that the file length.');
				callback(err);
				return false;
			}
		}
	}
	
	if ( ! isNaN(Number(range.end))) {
		if (length) {
			if (range.end > length - 1) {
				range.end = length - 1;
			}
		}
		if (range.end < 0) {
			err = new Error('The end value of a byte range can\'t be less than 0.');
			callback(err);
			return false;
		}
	}
	
	if (Number(range.end) > 0 && isNaN(Number(range.start))) {
		range.start = 0; // the node.js upstream is dumb about this ...
	}
	
	if (Number(range.start) >= 0 && isNaN(Number(range.end))) {
		range.end = length - 1;
	}
	
	if (range.start > range.end) {
		err = new Error('The start value of a byte range must be lower than the end value.');
		callback(err);
		return false;
	}
	
	if ( ! isNaN(range.start) && ! isNaN(range.end)) {
		if (length) {
			range.length = range.end - range.start + 1;
		}
	} else {
		delete(range.start);
		delete(range.end);
	}
	
	return range;
};
exports.filterByteRange = filterByteRange;

/**
 * The muscle of this library aka the function that makes all the request - response machinery
 * TODO: break it in smaller pieces since it's almost 300 LOC
 * 
 * @param {Object} config
 * @param {Object} options
 * @param body
 * @param handler
 * @param {Function} callback
 */
var makeRequest = function (config, options, body, handler, callback, requestId) {
	var transfer = new EventEmitter();
	var file, json, haveBodyHandler, bfile;
	
	if (requestId === undefined) {
		requestId = 0;
	}
	
	options.host = options.host || config.host;
	if (config.path) {
		options.path = config.path;
	}
	
	if (body) {
		switch (typeof body) {
			case 'string':
				options.headers['content-length'] = Buffer.byteLength(body);
			break;
			
			case 'object':
				haveBodyHandler = false;
				
				if (body instanceof Buffer) {
					haveBodyHandler = true;
					options.headers['content-length'] = body.length;
				}
				
				if (body instanceof Stream) {
					haveBodyHandler = true;
				}
				
				if ( ! haveBodyHandler) {
					if ( ! body.file) {
						throw new Error('Invalid body handler, expecting a file path.');
					}
					
					if (body.options) {
						body.options = filterByteRange(body.options, options.headers['content-length'], callback);
						
						if ( ! body.options) {
							return;
						}
						
						options.headers['content-length'] = body.options.length;
						delete(body.options.length);
					}
				}
			break;
			
			default:
				throw new Error('Invalid request body handler. Expecting a String or Object.');
		}
	}
	
	if (handler !== 'xml' && handler !== 'buffer' && handler !== 'stream' && handler !== 'json' && handler !== null) {
		try {
			if ( ! handler.file) {
				throw new Error('Invalid response body handler. Expecting an object containing a file path.');
			}
			
			handler.file = p.resolve(handler.file);
			file = fs.createWriteStream(handler.file);
			
			transfer.on('end', function () {
				transfer.removeAllListeners('end');
				file.on('open', function (fd) {
					fs.fsync(fd, function () {
						file.end();
					});
				});
			});
			
			file.on('error', function (error) {
				callback(error);
				file.destroy();
			});
			
			file.on('open', function (fd) {
				transfer.on('end', function () {
					transfer.removeAllListeners('end');
					fs.fsync(fd, function () {
						file.end();
					});
				});
			});
			
			file.on('close', function () {
				callback(null, {
					file: handler.file
				});
			});
		} catch (err) {
			callback(err);
			return;
		}
	}
	var aborted = false;
	var data = [];
	var request = https.request(options, function (response) {
		var parseXml = function (data) {
			// Set the XML parser
			var parser;
			if (dependencies.xml === 'libxml-to-js') {
				parser = xmlDep;
			} else { // xml2js
				parser = new xmlDep.Parser({mergeAttrs: true}).parseString;
			}
			
			parser(new Buffer(data).toString(), function (error, result) {
				if (response.statusCode !== 200) {
					error = new Error('API error with HTTP Code: ' + response.statusCode);
					error.headers = response.headers;
					error.code = response.statusCode;
					if (result) {
						error.document = result;
					}
					callback(error);
				} else if (error) {
					error.headers = response.headers;
					error.code = response.statusCode;
					callback(error);
				} else {
					callback(null, result);
				}
			});
		};
		
		if (response.statusCode === 307) { // oh great ... S3 crappy redirect
			requestId++;
			if (requestId <= 10) {
				var location = u.parse(response.headers.location);
				options.host = location.hostname;
				delete (options.agent);
				setTimeout(function () {
					makeRequest(config, options, body, handler, callback, requestId);
				}, 500 * requestId);
			} else {
				var error = new Error('Redirect loop detected after 10 retries.');
				error.headers = response.headers;
				error.code = response.statusCode;
				callback(error);
			}
		} else { // continue with the response
			if (handler === 'stream' && response.statusCode === 200) {
				callback(null, response);
				return;
			}
			
			response.on('data', function (chunk) {
				if ( ! aborted) {
					switch (handler) {
						case 'xml':
						case 'buffer':
						case 'stream':
						case 'json':
							data = data.concat(chunk.toByteArray());
						break;
						case null:
							if (response.statusCode !== 200 && response.statusCode !== 204) {
								data = data.concat(chunk.toByteArray());
							}
						break;
						default:
							if (response.statusCode !== 200) {
								data = data.concat(chunk.toByteArray());
							} else {
								try {
									file.write(chunk);
								} catch (e) {
									aborted = true;
									request.abort();
								} // handled by the error listener
							}
						break;
					}
				}
			});
			
			response.on('end', function () {
				if ( ! aborted) {
					switch (handler) {
						case 'xml':
						case 'stream':
							parseXml(data);
						break;
						case 'buffer':
							if (response.statusCode === 200) {
								callback(null, {
									headers: response.headers,
									buffer: new Buffer(data)
								});
							} else {
								parseXml(data);
							}
						break;
						case 'json':
							try {
								var json = JSON.parse(new Buffer(data).toString());
								if (response.statusCode === 200) {
									callback(null, json);
								} else {
									var error = new Error('API error with HTTP Code: ' + response.statusCode);
									error.headers = response.headers;
									error.code = response.statusCode;
									error.document = json;
									callback(error);
								}
							} catch (e) {
								return callback(e);
							}
						break;
						case null:
							switch (response.statusCode) {
								case 200:
								case 204:
									callback(null, response.headers);
								break;
								default:
									// treat it as error, parse the response
									parseXml(data);
								break;
							}
						break;
						default:
							if (response.statusCode !== 200) { // parse the error
								parseXml(data);
							} else {
								transfer.emit('end');
							}
						break;
					}
				}
			});
			response.on('close', function () {
				if ( ! aborted) {
					if (data.length > 0) {
						// Try parsing the data we have - most often it seems to be a well-formed response
						parseXml(data);
					} else {
						var error = new Error('The server prematurely closed the connection and there was no data.');
						error.headers = response.headers;
						error.code = response.statusCode;
						callback(error);
					}
				}
			});
		}
	});
	request.on('error', function (error) {
		callback(error);
	});
	if (body) {
		if (typeof body === 'string') {
			request.write(body);
			request.end();
			return;
		}
		if (typeof body === 'object') {
			if (body instanceof Buffer) {
				request.write(body);
				request.end();
				return;
			}
			
			if (body instanceof Stream) {
				body.resume();
				body.pipe(request);
				return;
			}
			
			if ( ! haveBodyHandler) {
				if (body.options) {
					bfile = fs.ReadStream(body.file, body.options);
				} else {
					bfile = fs.ReadStream(body.file);
				}
				bfile.on('data', function (chunk) {
					if ( ! aborted) {
						request.write(chunk);
					}
				});
				bfile.on('end', function () {
					if ( ! aborted) {
						request.end();
					}
				});
				bfile.on('error', function (error) {
					aborted = true;
					request.abort();
					callback(error);
				});
			}
		}
	} else {
		request.end();
	}
};
exports.makeRequest = makeRequest;

/**
 * Creates HMAC signatures for signing the requests as required by the AWS APIs
 * 
 * @param {String} secretAccessKey
 * @param {String} toSign
 * @param {String} algo
 * @returns {String}
 */
var createHmac = function (secretAccessKey, toSign, algo) {
	return crypto.createHmac(algo, secretAccessKey).update(toSign).digest('base64');
};
exports.createHmac = createHmac;

/**
 * Creates the signature string for requests which sign headers
 * 
 * @param {Object} config
 * @param {Object} clientHeaders
 * @param {String} clientBody
 * @returns {String}
 */
var signHeaders = function (config, clientHeaders, clientBody, date) {
	var toSign = ['POST', '/', '', 'date:' + date, 'host:' + config.host];
	var n, key, keys = [];
	
	for (key in clientHeaders) {
		if (clientHeaders.hasOwnProperty(key) && key.match(/^x-amz-/)) {
			keys.push(key);
		}
	}
	
	keys = keys.sort();
	var xAmz = '';
	
	for (n in keys) {
		if (keys.hasOwnProperty(n)) {
			key = keys[n];
			xAmz += key + ':' + clientHeaders[key] + '\n';
		}
	}
	
	toSign.push(xAmz);
	toSign.push(clientBody);
	
	var hash =  crypto.createHash('sha256');
	hash.update(new Buffer(toSign.join('\n'), 'utf8'));
	toSign = hash.digest('binary');
	
	return createHmac(config.secretAccessKey, new Buffer(toSign, 'binary'), 'sha256');
};
exports.signHeaders = signHeaders;

/**
 * Creates the signature string
 * 
 * @param {Object} config
 * @param {Object} query
 * @returns {String}
 */
var sign = function (config, query) {
	var n, key, keys = [];
	var sorted = {};
	for (key in query) {
		if (query.hasOwnProperty(key)) {
			keys.push(key);
		}
		
	}
	
	keys = keys.sort();
	
	for (n in keys) {
		if (keys.hasOwnProperty(n)) {
			key = keys[n];
			sorted[key] = query[key];
		}
	}
	
	var toSign = ['POST', config.host, config.path, qs.stringify(sorted)].join('\n');
	toSign = toSign.replace(/!/g, '%21');
	toSign = toSign.replace(/'/g, '%27');
	toSign = toSign.replace(/\*/g, '%2A');
	toSign = toSign.replace(/\(/g, '%28');
	toSign = toSign.replace(/\)/g, '%29');
	
	return createHmac(config.secretAccessKey, toSign, 'sha256');
};
exports.sign = sign;

/**
 * Authorizes an S3 request
 * 
 * @param {Object} config
 * @param {String} method
 * @param {Object} headers
 * @param {String} path
 * @param {Object} query
 * @returns {String}
 */
var authorize = function (config, method, headers, path, query) {
	var toSign = method + '\n';
	if (headers['content-md5']) {
		toSign += headers['content-md5'];
	}
	toSign += '\n';
	if (headers['content-type']) {
		toSign += headers['content-type'];
	}
	toSign += '\n' + headers.date + '\n';
	
	var n, key, keys = [];
	var sorted = {};
	
	for (key in headers) {
		if (headers.hasOwnProperty(key)) {
			var amzPrefix = key.substr(0, 5);
			if (amzPrefix === 'x-amz') {
				var type = typeof headers[key];
				if (type === 'string' || type === 'number') {
					keys.push(key);
				} else {
					console.error('Warning: the header %s has the %s value with the type %s. This may have unintended side effects.', key, headers[key], type);
				}
			}
		}
	}
	
	keys = keys.sort();
	
	for (n in keys) {
		if (keys.hasOwnProperty(n)) {
			key = keys[n];
			sorted[key] = String(headers[key]).trim();
		}
	}
	
	for (key in sorted) {
		if (sorted.hasOwnProperty(key)) {
			toSign += key + ':' + sorted[key] + '\n';
		}
	}
	
	if (config.useBucket) {
		path = '/' + config.useBucket + path;
	}
	toSign += path;
	
	if (query) {
		return 'AWSAccessKeyId=' + config.accessKeyId + '&Expires=' + headers.date + '&Signature=' + encodeURIComponent(createHmac(config.secretAccessKey, toSign, 'sha1'));
	}
	
	return 'AWS ' + config.accessKeyId + ':' + createHmac(config.secretAccessKey, toSign, 'sha1');
};
exports.authorize = authorize;

/**
 * Computes the Content-Length header where applicable
 * 
 * @param {Object} config
 * @param {String} file
 * @param {Object} headers
 * @param {Function} callback
 */
var contentLength = function (file, config, method, headers, path, callback) {
	fs.stat(file, function (err, stats) {
		if (err) {
			callback(err);
		} else {
			headers['content-length'] = stats.size;
			headers.authorization = authorize(config, method, headers, path);
			callback(null, headers);
		}
	});
};

/**
 * Normalizes the header names to lowercase
 * 
 * @param {Object} headers
 * @returns {Object}
 */
var normalizeHeaders = function (headers) {
	var name;
	
	for (name in headers) {
		if (headers.hasOwnProperty(name)) {
			var lowName = name.toLowerCase();
			var val = headers[name];
			delete (headers[name]);
			headers[lowName] = val;
		}
	}
	
	return headers;
};
exports.normalizeHeaders = normalizeHeaders;

/**
 * Returns the standard headers for an S3 request
 * 
 * @param {Object} config
 * @param {String} method
 * @param {Object} headers
 * @param {String} path
 * @param {Object} body
 * @returns {Object}
 */
var standardHeaders = function (config, method, headers, path, body, callback) {
	if ( ! callback) {
		callback = body;
		body = {};
	}
	var elements = u.parse(path);
	path = elements.pathname;
	if (elements.hash) {
		path += elements.hash;
	}
	path = path.replace('%27', "'");
	var query = tools.sortObject(qs.parse(elements.query));
	if ( ! lodash.isEmpty(query)) {
		var key, queryParts = [];
		for (key in query) {
			if (query.hasOwnProperty(key) && cfg.subResource[key] !== undefined) {
				if (query[key]) {
					queryParts.push(key + '=' + query[key]);
				} else {
					queryParts.push(key);
				}
			}
		}
		if (queryParts.length > 0) {
			path += '?' + queryParts.join('&');
		}
	}
	var hdr = lodash.merge(headers, {
		date: new Date().toUTCString()
	});
	hdr = normalizeHeaders(hdr);
	if (config.sessionToken) {
		hdr['x-amz-security-token'] = config.sessionToken;
	}
	if (body && body.file) {
		if ( ! hdr['content-type']) {
			// Set the MIME lookup module
			if (dependencies.mime === 'mime-magic') {
				mimeDep.fileWrapper(body.file, function (err, res) {
					if (err) {
						callback(err);
					} else {
						hdr['content-type'] = res;
						contentLength(body.file, config, method, hdr, path, callback);
					}
				});
			} else { // mime
				hdr['content-type'] = mimeDep.lookup(body.file);
				contentLength(body.file, config, method, hdr, path, callback);
			}
		} else {
			if ( ! hdr['content-length']) {
				contentLength(body.file, config, method, hdr, path, callback);
			}
		}
		return;
	}
	
	hdr.authorization = authorize(config, method, hdr, path);
	callback(null, hdr);
};
exports.standardHeaders = standardHeaders;

/**
 * Minimal check for path integrity
 * Escapes the path
 * 
 * @param {String} path
 * @param {Function} callback
 * @returns {Object}
 */
var checkPath = function (path, callback, query) {
	var error;
	
	if ( ! path) {
		error = new Error('No path specified.');
		callback(error);
		return false;
	}
	
	if (typeof path !== 'string') {
		error = new Error('The path must be a string.');
		callback(error);
		return false;
	}
	
	if (path.charAt(0) !== '/') {
		path = '/' + path;
	}
	
	if ( ! lodash.isEmpty(query)) {
		var i, queryPieces = [];
		for (i in query) {
			if (query.hasOwnProperty(i)) {
				if (query[i] !== null) {
					queryPieces.push(i + '=' + query[i]);
				} else {
					queryPieces.push(i);
				}
			}
		}
		
		query = queryPieces.join('&');
		if (path.indexOf('?') === -1) {
			path += '?';
		} else {
			path += '&';
		}
		path = path + query;
	}
	
	return encodeURI(path);
};
exports.checkPath = checkPath;

/**
 * Checks a canned ACL if it is valid
 * 
 * @param {String} acl
 * @param {Object} headers
 * @returns {Object}
 */
var checkAcl = function (acl, headers) {
	if (acl) {
		if (cfg.cannedAcls[acl] !== undefined) {
			headers['x-amz-acl'] = acl;
			return headers;
		}
		
		var error = new Error('Invalid ACL specification: ' + acl);
		return error;
	}
	
	return headers;
};
exports.checkAcl = checkAcl;

/**
 * Removes the extra weight from the API version
 * 
 * @param {Object} config
 * @returns {String}
 */
var squashApiVersion = function (config) {
	return config.query.Version.replace(/-/g, '');
};
exports.squashApiVersion = squashApiVersion;

/**
 * Find the rule according to the rule id
 * returns the rule and its index in the array
 * to facilitate the splice() if needed.
 * 
 * @param {String} id
 * @param {Object} lifecycle
 * @returns {Object}
 */
var findLifeCycleRule = function (id, lifecycle) {
	if ( ! (lifecycle.Rule instanceof Array)) {
		// When there is only one rule, response.Rule is not interpreted
		// as an array by libxml-to-js. We transform it to an array to
		// simplify the process below
		lifecycle.Rule = [lifecycle.Rule];
	}
	
	var i, existingRules = lifecycle.Rule;
	for (i = 0; i < existingRules.length; i++) {
		if (existingRules[i].ID === id) {
			return {
				index: i,
				rule: existingRules[i]
			};
		}
	}
};
exports.findLifeCycleRule = findLifeCycleRule;

/**
 * Common method for put and del
 * Serialize the lifecycle config to XML
 *
 * @param {Object} config
 * @param {Object} lifecycle
 * @param {Function} callback
 */
var putLifeCycleConfig = function (config, lifecycle, callback) {
	// Serialize response object to XML
	var i;
	var body = '<LifecycleConfiguration>';
	for (i = 0; i < lifecycle.Rule.length; i++) {
		body += '<Rule><ID>'
			+ lifecycle.Rule[i].ID + '</ID><Prefix>'
			+ lifecycle.Rule[i].Prefix + '</Prefix><Status>'
			+ lifecycle.Rule[i].Status + '</Status><Expiration><Days>'
			+ lifecycle.Rule[i].Expiration.Days + '</Days></Expiration></Rule>';
	}
	body += '</LifecycleConfiguration>';
	
	var headers = {};
	var md5 = crypto.createHash('md5');
	
	md5.update(body);
	headers['content-md5'] = md5.digest('base64');
	
	// put the new lifecycle configuration
	config.put('?lifecycle', headers, body, callback);
};
exports.putLifeCycleConfig = putLifeCycleConfig;
