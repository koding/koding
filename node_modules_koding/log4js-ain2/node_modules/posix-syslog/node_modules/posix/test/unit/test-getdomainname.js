var assert = require('assert');
var posix = require('../../lib/posix');

var domainname = posix.getdomainname();
console.log('domainname: ' + domainname);
assert.ok(typeof(domainname) === 'string');
