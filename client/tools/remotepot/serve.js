var ROOT_DIR = __dirname + '/../../../website';

var http = require('http');
var ecstatic = require('ecstatic')(ROOT_DIR);

var server = http.createServer(function (req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  ecstatic(req, res);
});

server.listen(8090);
console.log('listening on :8090');