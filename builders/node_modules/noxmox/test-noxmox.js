
//
// Copyright(c) 2011 Nephics AB
// MIT Licensed
//

// To run the tests you will need a file called awsauth.json in the parent path.
// The JSON file shall contain an object with the aws key, secret and bucketname.

var fs = require('fs');
var crypto = require('crypto');
var util = require('util');
var assert = require('assert');

var nox = require('./nox.js');
var mox = require('./mox.js');

runTests();

function runTests() {
  fs.readFile('../awsauth.json', 'utf8', function(err, data) {
    if (err) {
      console.log(err.message);
      return;
    }
    var options = JSON.parse(data);

    console.log('\nTesting mox client');
    var moxclient = mox.createClient(options);
    test(moxclient, function() {
      var noxclient = nox.createClient(options);
      console.log('\nTesting nox client');
      test(noxclient, function(){
        console.log('\nAll tests completed');
      });
    });
  });
}


function test(client, callback) {
  var name = 'test-noxmox.txt';
  t1();
  function t1() {
    var buf = new Buffer('Testing the noxmox lib.');
    upload(client, name, buf, t2);
  }
  function t2() {
    stat(client, name, t3);
  }
  function t3() {
    download(client, name, t4);
  }
  function t4() {
    remove(client, name, t5);
  }
  function t5() {
    statRemoved(client, name, t6);
  }
  function t6() {
    downloadRemoved(client, name, t7);
  }
  function t7() {
    removeRemoved(client, name, callback);
  }
}

function logErrors(req) {
  req.on('error', function(err) {
    console.log(err.message || err);
  });
}

function logResponse(res) {
  console.log('status code: ' + res.statusCode);
  console.log('headers: ' + util.inspect(res.headers));
}


function upload(client, name, buf, callback) {
  console.log('\nFile upload');
  var req = client.put(name, {
    'Content-Type':'text/plain',
    'Content-Length':buf.length,
    'Content-MD5': crypto.createHash('md5').update(buf).digest('base64')
  });
  logErrors(req);
  req.on('continue', function() {
    req.end(buf);
  });
  req.on('response', function(res) {
    logResponse(res);
    res.on('data', function(chunk) {
      console.log(chunk);
    });
    res.on('end', function() {
      console.log('Response finished');
      assert.equal(res.statusCode, 200);
      callback();
    });
  });
}


function stat(client, name, callback) {
  var req = client.head(name);
  logErrors(req);
  console.log('\nFile stat');
  req.on('response', function(res) {
    logResponse(res);
    res.on('data', function(chunk) {
      console.log(chunk);
    });
    res.on('end', function() {
      console.log('Response finished');
      assert.equal(res.statusCode, 200);
      callback();
    });
  });
  req.end();
}


function statRemoved(client, name, callback) {
  var req = client.head(name);
  logErrors(req);
  console.log('\nNonexistent file stat');
  req.on('response', function(res) {
    logResponse(res);
    res.on('data', function(chunk) {
      console.log(chunk);
    });
    res.on('end', function() {
      console.log('Response finished');
      assert.equal(res.statusCode, 404);
      callback();
    });
  });
  req.end();
}


function download(client, name, callback) {
  var req = client.get(name);
  logErrors(req);
  console.log('\nFile download');
  req.on('response', function(res) {
    logResponse(res);
    var len = 0;
    res.on('data', function(chunk) {
      len += chunk.length;
    });
    res.on('end', function() {
      console.log('Downloaded ' + len + ' bytes of file data');
      assert.equal(res.statusCode, 200);
      callback();
    });
  });
  req.end();
}

function downloadRemoved(client, name, callback) {
  var req = client.get(name);
  logErrors(req);
  console.log('\nNonexistent file download');
  req.on('response', function(res) {
    logResponse(res);
    res.on('data', function(chunk) {
      console.log(chunk.toString());
    });
    res.on('end', function() {
      assert.equal(res.statusCode, 404);
      callback();
    });
  });
  req.end();
}


function remove(client, name, callback) {
  var req = client.del(name);
  logErrors(req);
  console.log('\nFile delete');
  req.on('response', function(res) {
    logResponse(res);
    res.on('data', function(chunk) {
      console.log(chunk);
    });
    res.on('end', function() {
      console.log('Response finished');
      assert.equal(res.statusCode, 204);
      callback();
    });
  });
  req.end();
}


function removeRemoved(client, name, callback) {
  // Trying to removing a nonexistent file, looks the same
  // as removing an existent file (status code 204).
  remove(client, name, callback);
}
