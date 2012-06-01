# noxmox

Node Amazon S3 client and mock-up modules.

This library provides two node.js modules implementing the Amazon S3 REST API functions:

* `nox` - A simple Amazon S3 client supporting the `put()`, `get()` and `del()` methods for an existing bucket.

* `mox` - A simple S3 mock-up, supporting same methods as `nox`, emulating Amazon S3 on a local drive.

# Features

* Simple to learn and easy to use, get started quickly with Amazon S3.
* Interchangeable modules allowing for developing and testing offline, i.e. storing
  files on the local file system, without using the S3 storage space.
* The S3 client is just a simple wrapper around node's native `http.client` api.

# Interface overview

The `nox` and `mox` modules each exports one method called:

* `createClient(options)` - Create client with given options, which is an object containing the AWS key and secret, and the bucket name.

Both `nox` and `mox` clients support the same methods:

* `put(filename, headers={})` - Put file to S3 / local drive.
* `get(filename, headers={})` - Get file from S3 / local drive.
* `delete(filename, headers={})` - Delete file from S3 / local drive.

# Example: walk-trough

The following example is a walk-through of uploading and downloading a file from S3.

Require the `noxmox` module and create an `nox` S3 client:

    var client = require('noxmox').nox.createClient({
      key: '<api-key-here>',
      secret: '<secret-here>',
      bucket: 'mybucket'
    });

Require the file system module and read a file synchronously from disk:

    var data = require('fs').readFileSync('<filename>');
    
Create a request for storing the file in the S3 bucket:

    var req = client.put('<filename>', {'Content-Length': data.length});
    
Listen for the `continue` event emitted by the request, then write the file
data and end the request:

    req.on('continue', function() {
      req.end(data);
    });

To get the acknowledgement and the transaction information from Amazon S3,
listen for the response event and retrieve the response body:

    req.on('response', function(res) {
      res.on('data', function(chunk) {
        console.log(chunk);
      });
      res.on('end', function() {
        if (res.statusCode === 200) {
          console.log('File is now stored on S3');
        }
      });
    });

The file data can be retrieved again with the following code:

    var req = client.get('<filename>');
    req.end();
    req.on('response', function(res) {
      var chunks = [];
      req.on('data', function(chunk) {
        chunks.push(chunk);
      });
      req.on('end', function() {
        var data = chunks.join('');
        console.log('Retrieved ' + data.length + ' bytes of file data');
      });
    });

Delete the file from S3:

    var req = client.del('<filename>');
    req.end();
    req.on('response', function(res) {
      res.on('data', function(chunk) {
        console.log(chunk);
      });
      res.on('end', function() {
        if (res.statusCode === 204) {
          console.log('File is now removed from S3');
        }
      });
    });
   
In an actual implementation, the file data should be read and upload asynchronously in chunks, not
synchronously as in this simple example.

The `nox` and `mox` modules are interchangeable, so the above example
can be repeated with `mox` replacing `nox` when creating the client. The file
will then be stored on the local hard drive in the default location `/tmp/mox`.

## Advanced topics

Make the uploaded file public on S3 by passing the header `'x-amz-acl':'public'` when calling `put()`.

Change the default local storage location for `mox` using the option `prefix:<path>` for specifying the path to store files.

# Acknowledgements

The code to `nox` is partly derived from the [knox](https://github.com/LearnBoost/knox) project, and
in particularly the authentication module (auth.js) is an exact copy of the one from `knox`. These parts
are Copyright (c) 2010 LearnBoost &lt;dev@learnboost.com&gt; and licensed under the MIT license.

Note: `nox` will unlike `knox` by default keep the uploaded files private, as is also the Amazon S3 default.

# License

Licensed under the MIT License:

Copyright (c) 2011 Nephics AB

Copyright (c) 2010 LearnBoost &lt;dev@learnboost.com&gt;

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


