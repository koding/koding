/*
 * files.js: Instance methods for working with files from AWS S3
 *
 * (C) 2012 Nodejitsu Inc.
 *
 */

var fs = require('fs'),
    filed = require('filed'),
    mime = require('mime'),
    request = require('request'),
    utile = require('utile'),
    qs = require('querystring'),
    base = require('../../../core/storage'),
    pkgcloud = require('../../../../../lib/pkgcloud'),
    storage = pkgcloud.providers.amazon.storage;

const MAX_UPLOAD = 5 * 1024 * 1024 * 1024;

//
// ### function removeFile (container, file, callback)
// #### @container {string} Name of the container to destroy the file in
// #### @file {string} Name of the file to destroy.
// #### @callback {function} Continuation to respond to when complete.
// Destroys the `file` in the specified `container`.
//
exports.removeFile = function (container, file, callback) {
  if (container instanceof storage.Container) {
    container = container.name;
  }

  if (file instanceof storage.File) {
    file = file.name;
  }

  this._request({
      method: 'DELETE',
      container: container,
      path: file
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, res.statusCode == 204);
  });
};

exports.upload = function (options, callback) {
  if (typeof options === 'function' && !callback) {
    callback = options;
    options = {};
  }

  //
  // Optional helper function passed to `this._request`
  // in the case when no callback is passed to `.upload(options)`.
  //
  function onUpload(err, body, res) {
    return err
      ? callback(err)
      : callback(null, res.statusCode == 200, res);
  }

  var container = options.container,
      success = callback ? onUpload : null,
      apiStream,
      inputStream;

  if (container instanceof storage.Container) {
    container = container.name;
  }

  options.headers = options.headers || {};

  if (options.local) {
    inputStream = filed(options.local);
    options.headers['content-length'] = fs.statSync(options.local).size;
  }
  else if (options.stream) {
    inputStream = options.stream;
  }

  if (options.headers && !options.headers['content-type'] && options.remote) {
    options.headers['content-type'] = mime.lookup(options.remote);
  }

  // If the content-length is greater than 5gb, we need to force the
  // multi-part path by nuking the content-length header
  if (options.headers['content-length'] !== undefined &&
    parseInt(options.headers['content-length'], 10) > MAX_UPLOAD) {
    delete options.headers['content-length'];
  }

  if (options.headers['content-length'] !== undefined) {
    // Regular upload
    apiStream = this._request({
      method: 'PUT',
      upload: true,
      container: container,
      path: options.remote,
      headers: options.headers || {}
    }, success);
  } else {
    // Multi-part, 5mb chunk upload
    apiStream = this.multipartUpload(options, success);
  }

  if (inputStream) {
    inputStream.pipe(apiStream);
  }

  return apiStream;
};

exports.multipartUpload = function (options, callback) {
  var self = this,
      container = options.container,
      chunk = 5 * 1024 * 1024,
      chunksStarted = 0,
      chunksFinished = [],
      stream = new storage.ChunkedStream(chunk),
      ended = false;

  if (container instanceof storage.Container) {
    container = container.name;
  }

  // We're doing a lot of parallel stuff there,
  // but callback should be called only once
  function handleResponse(err, body, res) {
    if (handleResponse.called) return;
    handleResponse.called = true;
    callback && callback(err, body, res);
  }

  handleResponse.called = false;

  // Wait for first data event, probably file is less than 5 mbs and
  // we don't need that multipart thing at all
  var first = null,
      fastCase = true;

  stream.once('data', function (data) {
    // Good case - all data fits in one chunk
    if (fastCase) {
      if (data.length < chunk && !first) {
        first = data;
        return;
      } else {
        fastCase = false;

        // Emit accumulated chunk
        self.emit('data', first);
        first = null;
      }
    }

    stream.pause();
    self._xmlRequest({
      method: 'POST',
      container: container,
      // Don't use the qs option here because there's no way to turn an object
      // parsed with qs into just ?uploads. i.e. { uploads: null } turns into
      // '?uploads=' which breaks signing
      path: options.remote + '?uploads'
    }, function (err, body, res) {
        if (err) {
          return handleResponse(err);
        }

        if (res.statusCode !== 200) return handleResponse(res.statusCode, res);

        // Upload rest
        function onChunk(chunk) {
          stream.pause();
          uploadChunk(body.UploadId, chunk, function (err, chunk) {
            if (err) return handleResponse(err);

            finish(chunk);
            stream.resume();
          });
        }
        stream.on('data', onChunk);

        // Upload existing chunk
        onChunk(data);
      }
    );
  });

  stream.on('end', function () {
    if (fastCase) {
      // Upload with default method once again
      var rstream = self.upload(utile.mixin({}, options, {
        stream: null,
        headers: utile.mixin({}, options.headers, {
          'content-length': first.length
        })
      }), handleResponse);
      rstream.end(first);
      return;
    }

    ended = true;
    finish();
  });

  function uploadChunk(uploadId, data, uploadCallback) {
    // Ignore empty chunks
    if (data.length === 0) return;

    var id = ++chunksStarted,
        chunk = {
          uploadId: uploadId,
          id: id,
          etag: null
        };

    var stream = self._request({
      method: 'PUT',
      upload: true,
      path: options.remote,
      container: container,
      qs: {
        partNumber: id,
        uploadId: uploadId
      },
      headers: utile.mixin({}, options.headers, {
        'content-length': data.length
      })
    }, function (err, body, res) {
      if (err) { return uploadCallback(err); }
      if (res.statusCode != 200) return uploadCallback(res.statusCode);

      chunk.etag = res.headers.etag;
      uploadCallback(null, chunk);
    });
    stream.write(data);
    stream.end();
  }

  function finish(chunk) {
    if (chunk) chunksFinished.push(chunk);

    // We must send request only if:
    //  - stream was ended
    //  - we was doing multipart request
    //  - all chunks were uploaded
    if (!ended ||
        chunksFinished.length === 0 ||
        chunksFinished.length !== chunksStarted) {
      return;
    }

    // Sort chunks in ascending order
    chunksFinished.sort(function (a, b) {
      return a.id > b.id ? 1 : a.id < b.id ? -1 : 0;
    });

    var body = '<CompleteMultipartUpload>' +
                  chunksFinished.map(function (chunk) {
                    return '<Part>' +
                      '<PartNumber>' + chunk.id + '</PartNumber>' +
                      '<ETag>' + chunk.etag + '</ETag>' +
                    '</Part>';
                  }).join('') +
               '</CompleteMultipartUpload>';

    // Send "Complete Multipart Upload" request
    self._request({
      method: 'POST',
      container: container,
      path: options.remote,
      qs: {
        uploadId: chunksFinished[0].uploadId
      },
      headers: {
        'Content-Length': Buffer.byteLength(body)
      },
      body: body
    }, function (err, body, res) {
      handleResponse(err, res.statusCode == 200);
    });
  }

  return stream;
};

exports.download = function (options, callback) {
  var self = this,
      success = callback ? onDownload : null,
      container = options.container,
      inputStream,
      apiStream;

  //
  // Optional helper function passed to `this._request`
  // in the case when no callback is passed to `.download(options)`.
  //
  function onDownload(err, body, res) {
    return err
      ? callback(err)
      : callback(null, new (storage.File)(self, utile.mixin(res.headers, {
          container: container,
          name: options.remote
        })));
  }

  if (container instanceof storage.Container) {
    container = container.name;
  }

  if (options.local) {
    inputStream = filed(options.local);
  }
  else if (options.stream) {
    inputStream = options.stream;
  }

  apiStream = this._request({
    path: options.remote,
    container: container,
    download: true
  }, success);

  if (inputStream) {
    apiStream.pipe(inputStream);
  }

  return apiStream;
};

exports.getFile = function (container, file, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
      self = this;

  this._request(
    {
      method: 'HEAD',
      container: containerName,
      path: file
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, new storage.File(self, utile.mixin(res.headers, {
          container: container,
          name: file
        })));
  });
};

exports.getFiles = function (container, options, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
      self = this;

  if (typeof options === 'function') {
    callback = options;
    options = null;
  }

  this._xmlRequest(
    {
      container: containerName,
      qs: options
    },
    function (err, body, res) {
      return err
        ? callback(err)
        : callback(null, self._toArray(body.Contents).map(function (file) {
            file.container = container;
            return new storage.File(self, file);
          }));
    }
  );
};

