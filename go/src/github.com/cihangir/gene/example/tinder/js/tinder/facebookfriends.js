var iz, processRequest;
iz = require('iz');
processRequest = require('./_request.js');
module.exports = (function(o) {
  return {
    Create: function(data, callback) {
      rules = {
        sourceId: iz(f.sourceId).required().minLength(1),
        targetId: iz(f.targetId).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/facebookfriends/create', data, callback)
    },
    Delete: function(data, callback) {
      rules = {
        sourceId: iz(f.sourceId).required().minLength(1),
        targetId: iz(f.targetId).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/facebookfriends/delete', data, callback)
    },
    Mutuals: function(data, callback) {
      return processRequest(o.baseUrl + '/facebookfriends/mutuals', data, callback)
    },
    One: function(data, callback) {
      rules = {
        sourceId: iz(f.sourceId).required().minLength(1),
        targetId: iz(f.targetId).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/facebookfriends/one', data, callback)
    },
  }
})(o);