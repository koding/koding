var iz, processRequest;
iz = require('iz');
processRequest = require('./_request.js');
module.exports = (function(o) {
  return {
    Create: function(data, callback) {
      rules = {
        id: iz(null).required().minLength(1),
        screenName: iz(p.screenName).required().minLength(4),
        screenName: iz(p.screenName).required().maxLength(20),
        location: iz(p.location).required().maxLength(30),
        description: iz(p.description).required().maxLength(160),
        createdAt: iz(p.createdAt).required().date(),
        updatedAt: iz(p.updatedAt).required().date(),
        deletedAt: iz(p.deletedAt).required().date()
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/profile/create', data, callback)
    },
    Delete: function(data, callback) {
      return processRequest(o.baseUrl + '/profile/delete', data, callback)
    },
    MarkAs: function(data, callback) {
      rules = {
        id: iz(null).required().minLength(1)
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/profile/markas', data, callback)
    },
    One: function(data, callback) {
      return processRequest(o.baseUrl + '/profile/one', data, callback)
    },
    Update: function(data, callback) {
      rules = {
        id: iz(null).required().minLength(1),
        screenName: iz(p.screenName).required().minLength(4),
        screenName: iz(p.screenName).required().maxLength(20),
        location: iz(p.location).required().maxLength(30),
        description: iz(p.description).required().maxLength(160),
        createdAt: iz(p.createdAt).required().date(),
        updatedAt: iz(p.updatedAt).required().date(),
        deletedAt: iz(p.deletedAt).required().date()
      };
      areRules = are(rules);
      if (!areRules.validFor(data)){
        return callback(areRules.getInvalidFields());
      }
      return processRequest(o.baseUrl + '/profile/update', data, callback)
    },
  }
})(o);