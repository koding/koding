var http = require('http');
var ecstatic = require('ecstatic');
http.createServer(ecstatic({ root: __dirname + '/../../../website' })).listen(8090);
console.log('listening on :8090');