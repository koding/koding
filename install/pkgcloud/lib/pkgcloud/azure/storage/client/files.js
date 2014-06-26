/*
 * files.js: Instance methods for working with files (blobs) from Azure
 *
 * (C) Microsoft Open Technologies, Inc.
 *
 */

var fs = require('fs'),
  filed = require('filed'),
  mime = require('mime'),
  request = require('request'),
  utile = require('utile'),
  urlJoin = require('url-join'),
  qs = require('querystring'),
  base = require('../../../core/storage'),
  AzureConstants = require('../../utils/constants'),
  pkgcloud = require('../../../../../lib/pkgcloud'),
  storage = pkgcloud.providers.azure.storage;

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
    method:'DELETE',
    path: urlJoin(container, file)
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, res.statusCode == 202);
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
      : callback(null, res.statusCode === 200 || res.statusCode === 201, res);
  }

  var container = options.container,
      success = callback ? onUpload : null,
      path,
      rstream,
      lstream;

  if (container instanceof storage.Container) {
    container = container.name;
  }

  options.headers = options.headers || {};

  if (options.local) {
    lstream = filed(options.local);
    options.headers['content-length'] = fs.statSync(options.local).size;
  }
  else if (options.stream) {
    lstream = options.stream;
  }

  if (options.headers && !options.headers['content-type'] && options.remote) {
    options.headers['content-type'] = mime.lookup(options.remote);
  }

  options.headers['x-ms-blob-type'] = AzureConstants.BlobConstants.BlobTypes.BLOCK;

  path = urlJoin(container, options.remote);

  if (options.azureBlockId) {
    options.qs = {
      comp: 'block',
      blockid: options.azureBlockId
    }
  }

  if (options.headers['content-length'] !== undefined) {
    // Regular upload
    rstream = this._request({
      method: 'PUT',
      upload: true,
      path: path,
      headers: options.headers || {},
      qs: options.qs
    }, success);
  } else {
    // Multi-part, 5mb chunk upload
    rstream = this.multipartUpload(options, success);
  }

  if (lstream) lstream.pipe(rstream);

  return rstream;
};

var getBlockId = function (a, b) {
  return "block" + ((1e15 + a + "").slice(-b));
};

exports.multipartUpload = function (options, callback) {
  var self = this,
    container = options.container,
    chunk = AzureConstants.BlobConstants.DEFAULT_WRITE_BLOCK_SIZE_IN_BYTES,
    numBlocks = 0,
    chunksFinished = [],
    stream = new storage.ChunkedStream(chunk),
    ended = false;

  if (container instanceof storage.Container) {
    container = container.name;
  }

  stream.on('data', function (data) {
    stream.pause();
    options.azureBlockId = getBlockId(numBlocks++, 15);
    options.headers['content-length'] = data.length;

    var next = function (err, body, res) {
      // TODO What to do if err here?
      // TODO MUST FIX
      if (!ended) {
        stream.resume();
      } else {
        self.sendBlockList(options, numBlocks, callback);
      }
    };

    var rstream = self.upload(options, next);
    rstream.write(data);
    rstream.end();
  });

  stream.on('end', function (data) {
    ended = true;
  });

  return stream;
};

exports.sendBlockList = function (options, numBlocks, callback) {
  var container = options.container,
      body,
      path,
      qs;

  if (container instanceof storage.Container) {
    container = container.name;
  }

  options.headers = options.headers || {};

  // remove x-ms-blob-type header or request will fail
  if (options.headers['x-ms-blob-type']) {
    delete options.headers['x-ms-blob-type'];
  }

  if (options.headers['content-type']) {
    options.headers['x-ms-blob-content-type'] = options.headers['content-type'];
  } else if (options.remote) {
    options.headers['x-ms-blob-content-type'] = mime.lookup(options.remote);
  }

  path = urlJoin(container, options.remote);
  qs = {
    comp: 'blocklist'
  };

  body = '<?xml version="1.0" encoding="utf-8"?>';
  body += '<BlockList>';
  for (var i = 0; i < numBlocks; i++) {
    body += '<Latest>' + encodeURIComponent(getBlockId(i, 15)) + '</Latest>';
  }
  body += '</BlockList>';

  options.headers['content-length'] = body.length;

  this._request({
    method: 'PUT',
    path: path,
    body: body,
    headers: options.headers,
    qs: qs
  }, function (err, body, res) {
    return err
      ? callback && callback(err)
      : callback && callback(null, res.statusCode === 201, res);
  });
};

exports.download = function (options, callback) {
  var self = this,
      success = callback ? onDownload : null,
      container = options.container,
      lstream,
      rstream;

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
    lstream = filed(options.local);
  }
  else if (options.stream) {
    lstream = options.stream;
  }

  rstream = this._request({
    path: urlJoin(container, options.remote),
    download: true
  }, success);

  if (lstream) {
    rstream.pipe(lstream);
  }

  return rstream;
};

exports.getFile = function (container, file, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
    self = this;

  this._request({
    method: 'GET',
    path: urlJoin(containerName, file)
  }, function (err, body, res) {
    return err
      ? callback(err)
      : callback(null, new storage.File(self, utile.mixin(res.headers, {
          container: container,
          name: file
        })));
  });
};

exports.getFiles = function (container, download, callback) {
  var containerName = container instanceof base.Container ? container.name : container,
    self = this;

  this._xmlRequest({
    method: 'GET',
    path: containerName,
    qs: {
      restype: 'container',
      comp: 'list'
    }
  }, function (err, body, res) {
    if (err) {
      return callback(err);
    }
    if (body.Blobs && body.Blobs.Blob) {
      return callback(null, self._toArray(body.Blobs.Blob).map(function (file) {
        file.container = container;
        return new storage.File(self, file);
      }));
    }

    callback(null, []);
  });
};

