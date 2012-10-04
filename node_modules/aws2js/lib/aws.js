'use strict';

// makes JSLint STFU about 'unescape' since the reasoning is retarded:
// we aren't unescaping URLs in the first place, therefore there's no URL decoding to break
/*global unescape*/
/*jslint regexp: true*/

// TODO: refactor

/* core modules */
var fs = require('fs');
var p = require('path');
var https = require('https');
var crypto = require('crypto');
var qs = require('querystring');

/* 3rd party modules */
var semver = require('semver');
var lodash = require('lodash');

/* the internally used modules */
var cfg = require('../config/aws.js');
var tools = require('./tools.js');
var internals = require('./internals.js');

/**
 * The client itself
 * 
 * @param {Object} config
 * @returns {Object}
 */
var client = function (config, httpOptions) {
	// adds the default host
	if ( ! config.host) {
		config.host = config.prefix + cfg.suffix;
	}
	
	/* globally accessible */
	
	/**
	 * Mandatory helper for setting the credentials
	 * 
	 * @param {String} accessKeyId
	 * @param {String} secretAccessKey
	 * @param {String} sessionToken
	 * @returns {Object}
	 */
	config.setCredentials = function (accessKeyId, secretAccessKey, sessionToken) {
		var credentials = {
			accessKeyId: accessKeyId,
			secretAccessKey: secretAccessKey
		};
		if (sessionToken) {
			credentials.sessionToken = sessionToken;
		}
		config = tools.merge(config, credentials);
		return config;
	};
	
	/**
	 * Sets the concurrency level for the core HTTPS support
	 * 
	 * @param value
	 * @returns {Object}
	 */
	config.setMaxSockets = function (value) {
		value = tools.absInt(value);
		if (value === 0) { // fallback to the default
			value = 5;
		}
		// easier than messing with the Agent instance
		https.Agent.defaultMaxSockets = value;
		return config;
	};
	
	/**
	 * Gets the defined endpoint
	 * 
	 * @returns {String}
	 */
	config.getEndPoint = function () {
		return config.host;
	};
	
	/* accessible by query APIs except the ones listed in cfg.noRegion */
	
	if (cfg.noRegion[config.prefix] === undefined) {
		/**
		 * Sets the region where the query API operates
		 * 
		 * @param {String} region
		 * @returns {Object}
		 */
		config.setRegion = function (region) {
			if (cfg.regions[region] !== undefined) {
				if (config.prefix === 'sdb' && region === 'us-east-1') {
					config = tools.merge(config, {
						host: config.prefix + cfg.suffix
					});
				} else {
					config = tools.merge(config, {
						host: config.prefix + '.' + region + cfg.suffix
					});
				}
				return config;
			}
			
			throw new Error('Invalid region: ' + region);
		};
	}
	
	/* in use by the query APIs */
	
	/* SQS client API */
	if (config.prefix === 'sqs') {
		/**
		 * Sets the path to hit a SQS queue
		 * Must be formatted as the full path
		 * 
		 * @param {String} queue
		 * @returns {Object}
		 */
		config.setQueue = function (queue) {
			queue = String(queue);
			if( queue.match(/\/[0-9]{12}\/.*\//) ){
				config.path = queue;
				return config;
			}
			
			throw new Error('Invalid queue path: ' + queue);
		};
	}
	
	if (config.prefix !== 's3') {
		/**
		 * Gets the defined API version
		 * 
		 * @returns {String}
		 */
		config.getApiVersion = function () {
			return config.query.Version;
		};
		
		/**
		 * Sets the query API version
		 * 
		 * @param {String} version
		 * @returns {Object}
		 */
		config.setApiVersion = function (version) {
			version = String(version);
			if (version.match(/\d{4}-\d{2}-\d{2}/)) {
				config.query.Version = version;
				return config;
			}
			
			throw new Error('Invalid version specification for client.setApiVersion().');
		};
		
		/**
		 * Sets the API remote HTTP path
		 * 
		 * @param {String} path
		 */
		config.setPath = function (path) {
			path = String(path);
			if ( ! path) {
				path = '/';
			}
			config.path = path;
			return config;
		};
		
		/**
		 * The "low level" call to the query APIs
		 * 
		 * @param {String} action
		 * @param {Object} query
		 * @param {Function} callback
		 */
		config.request = function (action, query, callback) {
			var now = new Date(), headers = {}, prefix, signature, clientHeaders, clientBody, responseBodyHandler, options;
			
			internals.checkConfig(config);
			if ( ! callback) {
				callback = query;
				query = {};
			}
			
			if (config.prefix !== 'dynamodb') {
				query.Action = action;
				if (config.sessionToken) {
					query.SecurityToken = config.sessionToken;
				}
				query = tools.merge(config.query, query);
			}
			
			if ( ! config.signHeader) {
				query = tools.merge(query, {
					Timestamp: now.toISOString(),
					AWSAccessKeyId: config.accessKeyId
				});
				query.Signature = internals.sign(config, query);
			} else {
				switch (config.prefix) {
					case 'email': // aka ses
						prefix = 'AWS3-HTTPS';
						signature = internals.createHmac(config.secretAccessKey, now.toUTCString(), 'sha256');
					break;
					
					case 'dynamodb':
						prefix = 'AWS3';
						clientHeaders = {
							'content-type': 'application/x-amz-json-1.0',
							'x-amz-target': 'DynamoDB_' + internals.squashApiVersion(config) + '.' + action,
							'x-amz-security-token': config.sessionToken
						};
						clientBody = JSON.stringify(query);
						// unescapes the UTF-8 chars, see #30
						clientBody = unescape(clientBody.replace(/\\u/g, '%u'));
						responseBodyHandler = 'json';
						signature = internals.signHeaders(config, clientHeaders, clientBody, now.toUTCString());
					break;
					
					default:
						throw new Error('The ' + String(config.prefix) + ' service is not supported for the signHeader signing method.');
				}
				
				headers = {
					host: config.host,
					date: now.toUTCString(),
					'x-amzn-authorization': prefix + ' AWSAccessKeyId=' + config.accessKeyId + ', Algorithm=HmacSHA256,' + 'Signature=' + signature
				};
			}
			
			if (config.prefix !== 'dynamodb') {
				clientHeaders = {
					'content-type': 'application/x-www-form-urlencoded; charset=utf-8'
				};
				clientBody = qs.stringify(query);
				responseBodyHandler = 'xml';
			}
			options = lodash.clone(httpOptions, true);
			options.method = 'POST';
			options.headers = tools.merge(headers, clientHeaders);
			internals.makeRequest(config, options, clientBody, responseBodyHandler, callback);
		};
		
		// deprecated method, will be removed in v1.0
		config.call = function() {
			// This is deprecated due to ambiguity with Function.prototype.call.
			console.error('Warning: aws2js use of .call() is deprecated.  Use .request() instead.');
			return config.request.apply(this, arguments);
		};
	}
	
	/* in use by the S3 REST API */
	
	if (config.prefix === 's3') {
		/* the low level methods */
		
		/**
		 * Wraps the GET requests to the S3 API
		 * 
		 * @param {String} path
		 * @param {Object} query
		 * @param {String} handler
		 * @param {Function} callback
		 */
		config.get = function (path, query, handler, callback) {
			if ( ! callback) {
				callback = handler;
				handler = query;
				query = {};
			}
			internals.checkConfig(config);
			path = internals.checkPath(path, callback, query);
			if ( ! path) {
				return;
			}
			internals.standardHeaders(config, 'GET', {}, path, function (err, headers) {
					if (err) {
						callback(err);
					} else {
						var options = lodash.clone(httpOptions, true);
						options.method = 'GET';
						options.path = path;
						options.headers = headers;
						internals.makeRequest(config, options, false, handler, callback);
					}
				}
			);
		};
		
		/**
		 * Wraps the HEAD requests to the S3 API
		 * 
		 * @param {String} path
		 * @param {Function} callback
		 */
		config.head = function (path, callback) {
			internals.checkConfig(config);
			path = internals.checkPath(path, callback);
			if ( ! path) {
				return;
			}
			internals.standardHeaders(config, 'HEAD', {}, path, function (err, headers) {
					if (err) {
						callback(err);
					} else {
						var options = lodash.clone(httpOptions, true);
						options.method = 'HEAD';
						options.path = path;
						options.headers = headers;
						internals.makeRequest(config, options, false, null, callback);
					}
				}
			);
		};
		
		/**
		 * Wraps the DELETE requests to the S3 API
		 * 
		 * @param {String} path
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.del = function (path, headers, callback) {
			if ( ! callback) {
				callback = headers;
				headers = {};
			}
			headers['content-length'] = 0;
			
			internals.checkConfig(config);
			path = internals.checkPath(path, callback);
			if ( ! path) {
				return;
			}
			internals.standardHeaders(config, 'DELETE', headers, path, function (err, headers) {
					if (err) {
						callback(err);
					} else {
						var options = lodash.clone(httpOptions, true);
						options.method = 'DELETE';
						options.path = path;
						options.headers = headers;
						internals.makeRequest(config, options, false, null, callback);
					}
				}
			);
		};
		
		/**
		 * Wraps the PUT requests to the S3 API
		 * 
		 * @param {String} path
		 * @param {Object} headers
		 * @param body
		 * @param {Function} callback
		 */
		config.put = function (path, headers, body, callback) {
			internals.checkConfig(config);
			path = internals.checkPath(path, callback);
			if ( ! path) {
				return;
			}
			if (body && body.file) {
				body.file = p.resolve(body.file);
			}
			if ( ! headers['content-length']) {
				headers = tools.merge(headers, {'content-length': 0});
			}
			internals.standardHeaders(config, 'PUT', headers, path, body, function (err, hdrs) {
					if (err) {
						callback(err);
					} else {
						var options = lodash.clone(httpOptions, true);
						options.method = 'PUT';
						options.path = path;
						options.headers = hdrs;
						internals.makeRequest(config, options, body, null, callback);
					}
				}
			);
		};
		
		/**
		 * Wraps the POST requests to the S3 API
		 * 
		 * @param {String} path
		 * @param {Object} headers
		 * @param body
		 * @param {Function} callback
		 */
		config.post = function (path, headers, body, callback) {
			internals.checkConfig(config);
			path = internals.checkPath(path, callback);
			if ( ! path) {
				return;
			}
			if (body.file) {
				body.file = p.resolve(body.file);
			}
			internals.standardHeaders(config, 'POST', headers, path, body, function (err, hdrs) {
					if (err) {
						callback(err);
					} else {
						hdrs.expect = '100-continue';
						var options = lodash.clone(httpOptions, true);
						options.method = 'POST';
						options.path = path;
						options.headers = hdrs;
						internals.makeRequest(config, options, body, 'xml', callback);
					}
				}
			);
		};
		
		/**
		 * Creates a "pre-signed" request URL
		 * 
		 * @param {String} protocol
		 * @param {String} method
		 * @param {String} path
		 * @param {Date} expires
		 * @param {Object} headers
		 */
		config.signUrl = function (protocol, method, path, expires, headers) {
			protocol = String(protocol).toLowerCase();
			if (protocol !== 'http' && protocol !== 'https') {
				throw new Error('Invalid protocol argument. Expecting: http, or https.');
			}
			
			method = String(method).toUpperCase();
			if (method !== 'GET' && method !== 'HEAD' && method !== 'POST' && method !== 'PUT' && method !== 'DELETE') {
				throw new Error('Invalid method argument. Expecting: GET, HEAD, POST, PUT, or DELETE');
			}
			
			if ( ! (expires instanceof Date)) {
				throw new Error('Expecting a Date object for the expires argument.');
			}
			
			if (path.charAt(0) !== '/') {
				path = '/' + path;
			}
			path = encodeURI(String(path));
			
			if ( ! headers) {
				headers = {};
			}
			
			// hacking the expires into the authorization method
			headers.date = Math.floor(expires.getTime() / 1000);
			
			var signature = internals.authorize(config, method, headers, path, true);
			
			var separator = '?';
			if (path.indexOf('?') !== -1) {
				separator = '&';
			}
			
			return protocol + '://' + config.host + path + separator + signature;
		};
		
		/* the S3 helpers */
		
		/**
		 * Sets the bucket name
		 * 
		 * @param {String} bucket
		 */
		config.setBucket = function (bucket) {
			config = tools.merge(config, {
				host: bucket + '.' + config.prefix + cfg.suffix,
				useBucket: bucket
			});
			return config;
		};
		
		/**
		 * Returns the define bucket or empty string
		 * 
		 * @returns {String}
		 */
		config.getBucket = function () {
			if (config.useBucket) {
				return config.useBucket;
			}
			return '';
		};
		
		/**
		 * Sets the S3 endpoint
		 * 
		 * @param {String} endpoint
		 */
		config.setEndPoint = function (endpoint) {
			return config.setBucket(endpoint);
		};
		
		/**
		 * Creates a S3 bucket
		 * 
		 * @param {String} bucket
		 * @param {String} acl
		 * @param {String} region
		 * @param {Function} callback
		 */
		config.createBucket = function (bucket, acl, region, callback) {
			config.setBucket(bucket);
			var headers = {
				'x-amz-acl': 'private'
			};
			var body = false;
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			if (region) {
				if (cfg.regions[region] !== undefined) {
					body = '<CreateBucketConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><LocationConstraint>' + cfg.regions[region] + '</LocationConstraint></CreateBucketConfiguration>';
				} else {
					var error = new Error('Invalid region: ' + region);
					callback(error);
					return;
				}
			}
			
			config.put('/', headers, body, callback);
		};
		
		/**
		 * Sets the canned ACLs for an existing bucket
		 * 
		 * @param {String} bucket
		 * @param {String} acl
		 * @param {Function} callback
		 */
		config.setBucketAcl = function (bucket, acl, callback) {
			config.setBucket(bucket);
			var headers = {
				'x-amz-acl': 'private'
			};
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			config.put('/?acl', headers, false, callback);
		};
		
		/**
		 * Puts a file to S3
		 * 
		 * @param {String} path
		 * @param {String} file
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.putFile = function (path, file, acl, headers, callback) {
			file = p.resolve(file);
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			headers.expect = '100-continue';
			var md5 = crypto.createHash('md5');
			var bf = fs.ReadStream(file);
			bf.on('data', function (chunk) {
				md5.update(chunk);
			});
			bf.on('end', function () {
				headers['content-md5'] = md5.digest('base64');
				config.put(path, headers, {
					file: file
				}, callback);
			});
			bf.on('error', function (error) {
				callback(error);
			});
		};
		
		// deprecated method, will be removed in v1.0
		config.putObject = function () {
			// This is deprecated due to ambiguity when using a file path vs. a string which happens to contain a valid file path
			console.error('Warning: aws2js/S3 use of .putObject() is deprecated.  Use .putFile() instead.');
			return config.putFile.apply(this, arguments);
		};
		
		/**
		 * Puts a Stream to S3
		 * 
		 * @param {String} path
		 * @param {Stream} stream
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.putStream = function (path, stream, acl, headers, callback) {
			stream.pause();
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			headers.expect = '100-continue';
			config.put(path, headers, stream, callback);
		};
		
		/**
		 * Puts a Buffer to S3
		 * 
		 * @param {String} path
		 * @param {Buffer} buffer
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.putBuffer = function (path, buffer, acl, headers, callback) {
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			headers.expect = '100-continue';
			if ( ! headers['content-md5']) {
				var md5 = crypto.createHash('md5');
				md5.update(buffer);
				headers['content-md5'] = md5.digest('base64');
			}
			
			config.put(path, headers, buffer, callback);
		};
		
		/**
		 * Sets the object canned ACLs
		 * 
		 * @param {String} path
		 * @param {String} acl
		 * @param {Function} callback
		 */
		config.setObjectAcl = function (path, acl, callback) {
			var headers = {
				'x-amz-acl': 'private'
			};
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			config.put(path + '?acl', headers, false, callback);
		};
		
		/**
		 * Sets the object meta-data
		 * 
		 * @param {String} path
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.setObjectMeta = function (path, acl, headers, callback) {
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			headers['x-amz-copy-source'] = '/' + config.useBucket + path;
			headers['x-amz-metadata-directive'] = 'REPLACE';
			config.head(path, function (error, response) {
				if (error) {
					callback(error);
				} else {
					headers['content-type'] = response['content-type'];
					config.put(path, headers, false, callback);
				}
			});
		};
		
		/**
		 * Copy an object from one S3 path to another
		 * Ported from http://s3tools.org/s3cmd
		 * 
		 * @param {String} source
		 * @param {String} destination
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 * @link http://docs.amazonwebservices.com/AmazonS3/latest/API/RESTObjectCOPY.html
		 * @link http://s3tools.org/s3cmd
		 */
		config.copyObject = function (source, destination, acl, headers, callback) {
			if ( ! callback) {
				callback = headers;
				headers = {};
			}
			
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			headers['x-amz-copy-source'] = source;
			headers['x-amz-metadata-directive'] = 'COPY';
			config.put(destination, headers, false, callback);
		};
		
		/**
		 * Moves an object from a bucket to another
		 * May be the same bucket
		 * 
		 * @param {String} source
		 * @param {String} destination
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.moveObject = function (source, destination, acl, headers, callback) {
			config.copyObject(source, destination, acl, headers, function(error, response) {
				if (error) {
					callback(error);
				} else {
					// extract the bucket name from the path-based object reference
					// as deleting objects requires host based addressing
					source = source.split('/');
					var bucket = source[0];
					delete(source[0]);
					source = source.join('/');
					
					// build a temporary reference to the old bucket
					// since s3.setBucket() may cause side effects
					// due to being in an async framework
					var host = bucket + '.' + config.prefix + cfg.suffix;
					
					config.del(source, {host: host}, callback);
				}
			});
		};
		
		// deprecated since it has limited usage vs. s3.moveObject()
		config.renameObject = function (source, destination, acl, headers, callback) {
			console.error('Warning: aws2js/S3 use of .renameObject() is deprecated.  Use .moveObject() instead.');
			var absSource = source;
			if (absSource.charAt(0) !== '/') {
				absSource = '/' + absSource;
			}
			absSource = '/' + config.useBucket + absSource;
			
			config.copyObject(absSource, destination, acl, headers, function (error, response) {
				if (error) {
					callback(error);
				} else {
					config.del(source, callback);
				}
			});
		};
		
        /**
         * Get the bucket lifecycle configuration.
         * Returns a 400 error if the bucket has no
         * lifecycle configuration (S3 behaviour).
         * 
         * @param {Function} callback
         */
        config.getLifeCycle = function (callback)  {
            internals.checkConfig(config);
            config.get('?lifecycle', 'xml', callback);
        };
		
        /**
         * Delete the bucket lifecycle configuration
         * 
         * @param {Function} callback
         */
        config.delLifeCycle = function (callback) {
            internals.checkConfig(config);
            config.del('?lifecycle', callback);
        };
		
        /**
         * Add a lifecycle rule to the bucket
         * lifecycle configuration
         * 
         * @param {String} id
         * @param {String} prefix
         * @param {String} expireInDays
         * @param {Function} callback
         */
        config.putLifeCycleRule = function (id, prefix, expireInDays, callback) {
            internals.checkConfig(config);
			
            // allow this method to have type number for expireInDays parameter
            expireInDays = String(expireInDays);
			
            // first retrieve existing rules
            config.getLifeCycle(function (error, response) {
                if (error) {
                    if (error.document && error.document.Code === 'NoSuchLifecycleConfiguration') {
                        // the bucket hasn't a lifecycle configuration, we need to create it
                        response = {Rule: []};
                    } else {
                        callback(error);
                        return;
                    }
                }
				
                // the bucket has a lifecycle configuration, we need to update it.
                // check if the rule for the specified id already exists
                var found = internals.findLifeCycleRule(id, response);
                if (found) {
                    // the rule exists, update it
                    var rule = found.rule;
                    rule.Prefix = prefix;
                    rule.Expiration.Days = expireInDays;
                } else {
                    // if not exists, create and add the new desired rule
                    response.Rule.push({
                        ID: id,
                        Prefix: prefix,
                        Status: 'Enabled',
                        Expiration: {
							Days: expireInDays
						}
                    });
                }
				
                // now put the new lifecycle configuration
                internals.putLifeCycleConfig(config, response, callback);
            });
        };
		
        /**
         * Deletes a specific rule
         * Returns an error if the bucket hasn't lifecycle
         * config or if the rule is not found.
         * 
         * @param {String} id
         * @param {Function} callback
         */
        config.delLifeCycleRule = function (id, callback) {
            internals.checkConfig(config);
			
            // first retrieve existing rules
            config.getLifeCycle(function (error, response) {
                if (error) {
                    // no rule to delete, error
                    callback(error);
					return;
                }
				
                var found = internals.findLifeCycleRule(id, response);
                if (found) {
                    // the rule exists
                    if (response.Rule.length === 1) {
                        // this is the only Rule of the lifecycle config
                        // because S3 doesn't accept empty lifecycle config,
                        // we must use the global delete
                        config.delLifeCycle(callback);
                        return;
                    }
                    // remove the rule
                    response.Rule.splice(found.index, 1);
                }
				
                // now put the new lifecycle configuration
                internals.putLifeCycleConfig(config, response, callback);
            });
        };
		
		/**
		 * Initiates a multipart upload
		 * 
		 * @param {String} path
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.initUpload = function (path, acl, headers, callback) {
			headers = internals.normalizeHeaders(headers);
			headers = internals.checkAcl(acl, headers);
			
			if (headers instanceof Error) {
				callback(headers);
				return;
			}
			
			config.post(path + '?uploads', headers, '', function (err, res) {
				if (err) {
					callback(err);
				} else {
					callback(null, {bucket: res.Bucket, key: res.Key, uploadId: res.UploadId});
				}
			});
		};
		
		/**
		 * Aborts a multipart upload
		 * 
		 * @param {String} path
		 * @param {String} uploadId
		 * @param {Function} callback
		 */
		config.abortUpload = function (path, uploadId, callback) {
			config.del(path + '?uploadId=' + uploadId, callback);
		};
		
		/**
		 * Completes a multipart upload
		 * 
		 * @param {String} path
		 * @param {String} uploadId
		 * @param {Object} uploadParts
		 * @param {Function} callback
		 */
		config.completeUpload = function (path, uploadId, uploadParts, callback) {
			var i, xml = '<CompleteMultipartUpload>';
			for (i in uploadParts) {
				if (uploadParts.hasOwnProperty(i)) {
					xml += '<Part><PartNumber>' + i + '</PartNumber><ETag>' + uploadParts[i] + '</ETag></Part>';
				}
			}
			xml += '</CompleteMultipartUpload>';
			config.post(path + '?uploadId=' + uploadId, {}, xml, callback);
		};
		
		/**
		 * Uploades a file part of a multipart upload
		 * 
		 * @param {String} path
		 * @param {Number} partNumber
		 * @param {String} uploadId
		 * @param fileHandler
		 * @param {Function} callback
		 */
		config.putFilePart = function (path, partNumber, uploadId, fileHandler, callback) {
			fileHandler.file = p.resolve(fileHandler.file);
			fileHandler.options = internals.filterByteRange(fileHandler.options, false, callback);
			if ( ! fileHandler.options) {
				return;
			}
			var md5 = crypto.createHash('md5');
			var bf = fs.ReadStream(fileHandler.file, fileHandler.options);
			bf.on('data', function (chunk) {
				md5.update(chunk);
			});
			bf.on('end', function () {
				var headers = {expect: '100-continue'};
				headers['content-md5'] = md5.digest('base64');
				config.put(path + '?partNumber=' + partNumber + '&uploadId=' + uploadId, headers, fileHandler, function (err, res) {
					if (err) {
						err.partNumber = partNumber;
						callback(err);
					} else {
						callback(null, {
							partNumber: partNumber,
							ETag: res.etag
						});
					}
				});
			});
			bf.on('error', function (error) {
				callback(error);
			});
		};
		
		/**
		 * Uploades a stream part of a multipart upload
		 * 
		 * @param {String} path
		 * @param {Number} partNumber
		 * @param {String} uploadId
		 * @param {String} stream
		 * @param {Object} headers
		 * @param {Function} callback
		 */
		config.putStreamPart = function (path, partNumber, uploadId, stream, headers, callback) {
			stream.pause();
			
			headers.expect = '100-continue';
			config.put(path + '?partNumber=' + partNumber + '&uploadId=' + uploadId, headers, stream, function (err, res) {
				if (err) {
					err.partNumber = partNumber;
					callback(err);
				} else {
					callback(null, {
						partNumber: partNumber,
						ETag: res.etag
					});
				}
			});
		};
		
		/**
		 * Uploades a buffer part of a multipart upload
		 * 
		 * @param {String} path
		 * @param {Number} partNumber
		 * @param {String} uploadId
		 * @param {Buffer} buffer
		 * @param {Function} callback
		 */
		config.putBufferPart = function (path, partNumber, uploadId, buffer, callback) {
			var headers = {expect: '100-continue'};
			var md5 = crypto.createHash('md5');
			md5.update(buffer);
			headers['content-md5'] = md5.digest('base64');
			config.put(path + '?partNumber=' + partNumber + '&uploadId=' + uploadId, headers, buffer, function (err, res) {
				if (err) {
					err.partNumber = partNumber;
					callback(err);
				} else {
					callback(null, {
						partNumber: partNumber,
						ETag: res.etag
					});
				}
			});
		};
		
		/**
		 * Uploads a file by using the S3 multipart upload API
		 * 
		 * @param {String} path
		 * @param {String} file
		 * @param {String} acl
		 * @param {Object} headers
		 * @param {Number} partSize
		 * @param {Function} callback
		 */
		config.putFileMultipart = function (path, file, acl, headers, partSize, callback) {
			if ( ! callback) {
				callback = partSize;
				partSize = 5242880;
			} else {
				partSize = Number(partSize);
				if (partSize < 5242880 || isNaN(partSize)) {
					partSize = 5242880;
				}
			}
			file = p.resolve(file);
			fs.stat(file, function (err, res) {
				if (err) {
					callback(err);
				} else {
					var size = res.size;
					if (size <= 5242880) { // fallback to s3.putFile()
						config.putFile(path, file, acl, headers, callback);
					} else { // multipart upload
						config.initUpload(path, acl, headers, function (err, res) {
							if (err) {
								callback(err);
							} else {
								var uploadId = res.uploadId;
								var count = Math.ceil(size / partSize);
								var errors = [];
								var aborted = false;
								var uploadParts = [];
								var finished = 0;
								var partNumber;
								var putFilePart = function (path, partNumber, uploadId, fileHandler, callback) {
									if ( ! aborted) {
										config.putFilePart(path, partNumber, uploadId, fileHandler, function (err, res) {
											if ( ! aborted) {
												if (err) {
													errors[partNumber]++;
													if (errors[partNumber] === 10) {
														aborted = true;
														config.abortUpload(path, uploadId, function (err, res) {
															if ( ! err) {
																err = new Error('Part ' + partNumber + ' failed the upload 10 times. Aborting the multipart upload.');
																err.partNumber = partNumber;
															} else {
																err.partNumber = partNumber;
															}
															callback(err);
														});
													} else {
														setTimeout(function () {
															putFilePart(path, partNumber, uploadId, fileHandler, callback);
														}, 500 * errors[partNumber]);
													}
												} else {
													uploadParts[res.partNumber] = res.ETag;
													finished++;
													if (finished === count) {
														config.completeUpload(path, uploadId, uploadParts, callback);
													}
												}
											}
										});
									}
								};
								for (partNumber = 1; partNumber <= count; partNumber++) {
									errors[partNumber] = 0;
									putFilePart(path, partNumber, uploadId, {
										file: file,
										options: {
											start: (partNumber - 1) * partSize,
											end: partNumber * partSize - 1
										}
									}, callback);
								}
							}
						});
					}
				}
			});
		};
		
		/**
		 * Wraps the Delete Multiple Objects S3 POST call
		 * 
		 * @param {Object} objects
		 * @param {Boolean} quiet
		 */
		config.delMultiObjects = function (objects, quiet, cb) {
			if (typeof cb !== 'function') {
				if (typeof quiet === 'function') {
					cb = quiet;
					quiet = undefined;
				} else {
					throw new Error('Expecting the callback to be a function for s3.delMultiObjects().');
				}
			}
			
			if (quiet !== true) {
				quiet = undefined;
			}
			
			var xml = '<Delete>';
			
			if (quiet) {
				xml += '<Quiet>true</Quiet>';
			}
			
			var idx;
			var count = objects.length;
			for (idx = 0; idx < count; idx++) {
				var object = objects[idx];
				if (typeof object.key === 'string') {
					xml += '<Object><Key>' + object.key + '</Key>';
					
					if (typeof object.versionId === 'string') {
						xml += '<VersionId>' + object.versionId + '</VersionId>';
					}
					
					xml += '</Object>';
				}
			}
			
			xml += '</Delete>';
			
			var headers = {};
			
			var md5 = crypto.createHash('md5');
			md5.update(xml);
			headers['content-md5'] = md5.digest('base64');
			
			config.post('?delete', headers, xml, cb);
		};
		
		/**
		 * Exposes the deprecated escapePath() helper
		 * 
		 * @param {String} path
		 * @returns {String}
		 */
		config.escapePath = tools.escapePath;
	}
	
	return config;
};

/**
 * The AWS API client loader
 * 
 * @param {String} service
 * @param {String} accessKeyId
 * @param {String} secretAccessKey
 * @param {String} sessionToken
 * @param {Object} httpOptions
 */
exports.load = function (service, accessKeyId, secretAccessKey, sessionToken, httpOptions) {
	if (service === 's3') {
		if (semver.eq(process.version, 'v0.6.9')) {
			throw new Error('FATAL: The S3 client is NOT supported under node.js v0.6.9.');
		}
	}
	
	if (semver.lt(process.version, 'v0.6.0')) {
		console.error('Warning: aws2js under node.js v0.4.10+ is deprecated. The support will be removed in aws2js v0.8.');
	}
	
	var clientTemplate = cfg.clients[service], key;
	if ( ! clientTemplate) {
		throw new Error('Invalid AWS client');
	}
	
	if (service !== 's3') {
		clientTemplate.path = '/';
	}
	
	var clientConfig = lodash.clone(clientTemplate, true);
	var result = client(clientConfig, httpOptions || {});
	if (accessKeyId && secretAccessKey) {
		result.setCredentials(accessKeyId, secretAccessKey, sessionToken);
	}
	
	return result;
};
