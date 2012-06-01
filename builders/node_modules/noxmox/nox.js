
// nox - S3 Client for node.js
//
// Copyright(c) 2011 Nephics AB
// MIT Licensed
//
// Some code parts derived from knox:
//   https://github.com/LearnBoost/knox
//   Copyright(c) 2010 LearnBoost <dev@learnboost.com>
//   MIT Licensed

var http = require('http');
var url = require('url');
var path = require('path');
var fs = require('fs');

var auth = require('./auth')


function merge(a, b) {
  Object.keys(b).forEach(function(key) {
    a[key] = b[key]
  });
  return a;
}


// Create a S3 client
//
// Required options:
//      key: aws key
//   secret: aws secret
//   bucket: aws bucket name
exports.createClient = function(options) {
  if (!options.key) throw new Error('aws "key" required');
  if (!options.secret) throw new Error('aws "secret" required');
  if (!options.bucket) throw new Error('aws "bucket" required');

  var endpoint = options.bucket + '.s3.amazonaws.com';

  function request(method, filename, headers) {
    var date = new Date;
    var headers = headers || {};

    // Default headers
    merge(headers, {
      Date:date.toUTCString(),
      Host:endpoint
    });

    // Authorization header
    headers.Authorization = auth.authorization({
      key:options.key,
      secret:options.secret,
      verb:method,
      date:date,
      resource:auth.canonicalizeResource(path.join('/', options.bucket, filename)),
      contentType:headers['Content-Type'],
      md5:headers['Content-MD5'],
      amazonHeaders:auth.canonicalizeHeaders(headers)
    });

    // Issue request
    var opts = {
      host:endpoint,
      port:80,
      method:method,
      path:path.join('/', filename),
      headers:headers
    };

    return http.request(opts);
  }

  var client = new function() {};

  client.put = function put(filename, headers) {
    headers.Expect = '100-continue';
    return request('PUT', filename, headers);
  };

  client.get = function get(filename, headers) {
    return request('GET', filename, headers);
  };

  client.head = function head(filename, headers) {
    return request('HEAD', filename, headers);
  };

  // Delete file
  client.del = function del(filename, headers) {
    return request('DELETE', filename, headers);
  };

  // Return an S3 presigned url to the given `filename`.
  client.signedUrl = function signedUrl(filename, expiration) {
    var epoch = Math.floor(expiration.getTime()/1000);
    var signature = auth.signQuery({
      secret:options.secret,
      date:epoch,
      resource:'/' + options.bucket + url.parse(filename).pathname
    });

    var url = 'http://' + path.join(endpoint, filename) +
      '?Expires=' + epoch +
      '&AWSAccessKeyId=' + options.key +
      '&Signature=' + encodeURIComponent(signature);

    return url;
  };

  client.url =
  client.http = function(filename){
    return 'http://' + path.join(this.endpoint, this.bucket, filename);
  };

  client.https = function(filename){
    return 'https://' + path.join(this.endpoint, filename);
  };

  return client;
};

