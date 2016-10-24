var mongodb = require('mongodb');
var async = require('async');

data = {
  "relationships": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.relationships"
  }, {
    "name": "sourceName_1",
    "key": {
      "sourceName": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }, {
    "name": "as_1",
    "key": {
      "as": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }, {
    "name": "sourceId_1",
    "key": {
      "sourceId": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }, {
    "name": "targetName_1",
    "key": {
      "targetName": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }, {
    "name": "targetId_1",
    "key": {
      "targetId": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }, {
    "name": "timestamp_1",
    "key": {
      "timestamp": 1
    },
    "ns": "koding.relationships",
    "sparse": true
  }],
  "jUsers": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jUsers"
  }, {
    "name": "username_1",
    "key": {
      "username": 1
    },
    "unique": true,
    "ns": "koding.jUsers"
  }, {
    "name": "email_1",
    "key": {
      "email": 1
    },
    "unique": true,
    "ns": "koding.jUsers"
  }],
  "jStackTemplates": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jStackTemplates"
  }],
  "jSecretNames": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jSecretNames"
  }],
  "jRegistrationPreferences": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jRegistrationPreferences"
  }],
  "jPermissionSets": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jPermissionSets"
  }],
  "jNames": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jNames"
  }, {
    "name": "name_1",
    "key": {
      "name": 1
    },
    "unique": true,
    "ns": "koding.jNames"
  }],
  "jMembershipPolicies": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jMembershipPolicies"
  }],
  "jGroups": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jGroups"
  }, {
    "name": "slug_1",
    "key": {
      "slug": 1
    },
    "unique": true,
    "ns": "koding.jGroups"
  }],
  "jGroupRoles": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jGroupRoles"
  }],
  "jDomainAliases": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jDomainAliases"
  }],
  "jComputeStacks": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jComputeStacks"
  }],
  "jAccounts": [{
    "name": "_id_",
    "key": {
      "_id": 1
    },
    "ns": "koding.jAccounts"
  }, {
    "name": "isExempt_1",
    "key": {
      "isExempt": 1
    },
    "ns": "koding.jAccounts"
  }],
  "jCounters":[
  {
    "v" : 1,
    "name" : "_id_",
    "key" : {
      "_id" : 1
    },
    "ns" : "koding.jCounters"
  },
  {
    "v" : 1,
    "name" : "namespace-type",
    "key" : {
      "namespace" : 1,
      "type" : 1
    },
    "unique" : true,
    "ns" : "koding.jCounters",
    "sparse" : true
  }
]
}

exports.up = function(db, next){
  async.eachOfSeries(data, function (items, collName, cb) {
      coll = db.collection(collName);
      async.eachOfLimit(items, 4, function (item, i, callback) {
          var keys = item.key;
          var options = item;
          delete options.key;
          delete options.ns;
          coll.ensureIndex(keys, options, function(err){
            if(err && err.code == 11000){
              return callback(null);
            }
            return callback(null);
          });
      }, cb);
  }, next);
};

exports.down = function(db, next){
    next();
};
