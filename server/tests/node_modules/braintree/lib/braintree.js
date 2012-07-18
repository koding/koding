require('coffee-script');
braintree = require('./braintree.coffee')

exports.connect = braintree.connect;
exports.version = braintree.version;
exports.Environment = braintree.Environment;
exports.errorTypes = braintree.errorTypes;
