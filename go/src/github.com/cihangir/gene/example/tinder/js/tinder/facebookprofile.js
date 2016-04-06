var iz, processRequest;
iz = require('iz');
processRequest = require('./_request.js');
module.exports = (function(o) {
  return {
    ByIDs: function(data, callback) {
      return processRequest(o.baseUrl + '/facebookprofile/byids', data, callback)
    },
    Create: function(data, callback) {
      rules = {
        firstName: iz(f.firstName).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/facebookprofile/create', data, callback)
    },
    One: function(data, callback) {
      return processRequest(o.baseUrl + '/facebookprofile/one', data, callback)
    },
    Update: function(data, callback) {
      rules = {
        firstName: iz(f.firstName).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/facebookprofile/update', data, callback)
    },
  }
})(o);