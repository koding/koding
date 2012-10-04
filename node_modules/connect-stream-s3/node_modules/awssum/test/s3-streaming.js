// ---------------------------------------------------------
//
// s3-streaming.js - test for streaming uploads to s3
//
// Copyright (c) 2012 Nathan Friedly - http://nfriedly.com
//
// License: http://opensource.org/licenses/MIT
//
// ---------------------------------------------------------

var http = require('http'),
    https = require('https'),
    fs = require('fs'),
    Buffer = require('buffer').Buffer;

var test = require("tap").test;

var awssum = require('../'),
    amazon = awssum.load('amazon/amazon'),
    S3 = awssum.load('amazon/s3').S3;

test("AwsSum.prototype.send tests", function(t) {
    t.plan(4);

    var FAKE_READABLE_STREAM = {on: function(){}, pipe: function(){}, readable: true};
    var FAKE_CONTENT_LENGTH = "12345";
    var FAKE_MD5 = "ASDF1234";

    var options = {
        BucketName: "asdf",
        ObjectName: "asdf",
        ContentLength: FAKE_CONTENT_LENGTH,
        Body:  FAKE_READABLE_STREAM
    };

    var s3 = new S3({
        accessKeyId     : 'key',
        secretAccessKey : 'secret',
        awsAccountId    : 'account_id',
        region          : amazon.US_EAST_1
    });
    s3.request = function(options) {
        t.equal(FAKE_READABLE_STREAM, options.body, "AweSum.prototype.request called with a ReadableStream body");
        t.equal(FAKE_CONTENT_LENGTH, options.headers['Content-Length'], "Content-length header remained intact");
        t.ok(typeof options.headers['Content-MD5'] == "undefined", "No Content-MD5 header was added");
    }
    s3.PutObject(options, function(err, data) {
        t.notOk(err, "putObject callback fired with error: " + JSON.stringify(err));
    });

    options.ContentMD5 = FAKE_MD5;
    s3.request = function(options) {
        t.equal(options.headers['Content-MD5'], FAKE_MD5, "Existing Content-MD5 header was kept");
    }
    s3.PutObject(options, function(err, data) {
        t.notOk(err, "putObject callback fired with error: " + JSON.stringify(err));
    });

    t.end();
});

// fake self-signed cert and private key
var SSL_CERT = "-----BEGIN CERTIFICATE-----\n" +
"MIIBfDCCASYCCQDQ1TLT4mhJWDANBgkqhkiG9w0BAQUFADBFMQswCQYDVQQGEwJV\n" +
"UzETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0\n" +
"cyBQdHkgTHRkMB4XDTEyMDMyMjA0NTAyN1oXDTEyMDQyMTA0NTAyN1owRTELMAkG\n" +
"A1UEBhMCVVMxEzARBgNVBAgTClNvbWUtU3RhdGUxITAfBgNVBAoTGEludGVybmV0\n" +
"IFdpZGdpdHMgUHR5IEx0ZDBcMA0GCSqGSIb3DQEBAQUAA0sAMEgCQQDGdrVT6h1o\n" +
"gK5de1D/Ef391nlu10EO1WOw58N3HJnyrE0D4/q1AoFww0YV5pvRdiJSyxZeD2cl\n" +
"+m9dfBnE2leDAgMBAAEwDQYJKoZIhvcNAQEFBQADQQBsaWZVQY2D/0jcRA7eZBA1\n" +
"JUU/jVasS7RraRKE3VeSsxL8P4WCCk0jDeIcFzZsSYgqfG7wCwwMZGG315qE5m1S\n" +
"-----END CERTIFICATE-----\n";

var SSL_KEY = "-----BEGIN RSA PRIVATE KEY-----\n" +
"MIIBOwIBAAJBAMZ2tVPqHWiArl17UP8R/f3WeW7XQQ7VY7Dnw3ccmfKsTQPj+rUC\n" +
"gXDDRhXmm9F2IlLLFl4PZyX6b118GcTaV4MCAwEAAQJAfxZfMVg28seMYMJp8Jyl\n" +
"6Bmic08WExikmREgwzKmhpWbKK0Gx8xn3ZWjXPpdcKyA8J6p1rns0IQyDCZi+oZN\n" +
"IQIhAPlXD5x7DEpa9bL1FItTstWQ2s4bS8luuT0aDAVNdYfxAiEAy8PDuXKFJzTz\n" +
"63owC4gdb63zgzJpUGOfiTYOy74K6rMCIQCExpK+nlvOIJ/kG1REWV7LEWcjCDAU\n" +
"ZQzpd7xc+oGS0QIgYKHuaDwPOZC7PKktr8pVa2krWsTFfQJB3mhsi+MMelECIQCi\n" +
"YmwpCQIFgQeiZ4RBksM4BXwpqvKKKpwlLG7Ae9Sdrw==\n" +
"-----END RSA PRIVATE KEY-----\n";

var FAKE_APP_PORT = 3100;
var FAKE_S3_PORT = 3101;

/**
 * In order to test with a "real" stream, we're creating a fake client and server. The client
 * uploads some data to the server, and the node "req" object passed to the server is a
 * ReadableStream containing that data. This ReadableStream is passed directly to
 * AwsSum.prototype.request as the body.
 * This test then sets up a fake s3 server to verify that the request() method properly copied the
 * streaming data to the s3 request. Because AweSum only allows for https requests, we've generated
 * a fake SSL key pair.
 */
test("AwsSum.prototype.request properly streams body contents", function(t) {
    t.plan(3);

    // some "random" data
    var REQUEST_BODY = "adsf " + SSL_CERT + "asdf2 " + SSL_KEY + "asdf3";
    var REQUEST_CONTENT_LENGTH = Buffer.byteLength(REQUEST_BODY).toString();

    // This portion represents an app that might use node-awssum
    // (except that we're bypassing the s3 methods here to call AwsSum.prototype.request directly)
    var s3 = new S3({
        accessKeyId     : 'key',
        secretAccessKey : 'secret',
        awsAccountId    : 'account_id',
        region          : amazon.US_EAST_1
    });
    var fakeServer = http.createServer(function(req, res) {
        s3.request({
            protocol : 'https',
            host: "localhost",
            port: FAKE_S3_PORT,
            path: "/",
            headers: {
                "Content-Length": req.headers["content-length"] // required by s3 (and AwsSum's S3.PutObject)
            },
            body: req, // http.ServerRequest is a Readable Stream
            params: []
        }, function(err, data){
            if(err) {
                t.notOk(true, "AwsSum.prototype.request reported an error: " + JSON.stringify(err));
                t.end();
            }
        });
        res.end();
    });
    fakeServer.listen(FAKE_APP_PORT);

    // this is a mocked s3 service - it receives requests over https and compares them to the expected result
    var fakeS3 = https.createServer({key: SSL_KEY, cert: SSL_CERT}, function(req, res) {
        t.ok(true, "fake s3 server called");
        t.equal(req.headers['content-length'], REQUEST_CONTENT_LENGTH, "Request had a correct content-length header");
        var data = '';
        req.on('data', function (chunk) {
            data += chunk.toString();
        });
        req.on('end', function() {
            t.equal(data, REQUEST_BODY, "Body was uploaded successfully");
            res.end();
            fakeServer.close();
            fakeS3.close();
            t.end();
        });
    });
    fakeS3.listen(FAKE_S3_PORT);

    // This is a fake user request that might hit the app
    var fakeClient = http.request({
        host: "localhost",
        port: FAKE_APP_PORT,
        path: "/test",
        method: "PUT",
        headers: {
            "Content-Length": REQUEST_CONTENT_LENGTH
        }
    });
    fakeClient.write(REQUEST_BODY);
    fakeClient.end();
});
