var async = require('async');

var mongodb = require('mongodb'),
  ObjectId = mongodb.ObjectID;

var data = {
  "jAccounts": [{
    "_id": ObjectId("57eb1227d038e29c4607d483"),
    "counts": {
      "followers": 0,
      "following": 0,
      "lastLoginDate": new Date("2016-09-28T01:13:56.757Z"),
      "likes": 0,
      "referredUsers": 0,
      "topics": 0
    },
    "isExempt": false,
    "lastLoginTimezoneOffset": 420,
    "meta": {
      "createdAt": new Date("2016-09-28T00:43:19.797Z"),
      "modifiedAt": new Date("2016-09-28T00:43:19.797Z"),
      "tags": null,
      "views": null,
      "votes": null,
      "likes": 0
    },
    "onlineStatus": "online",
    "profile": {
      "nickname": "rainforestqa99",
      "hash": "27f698f8ed83f59b98b566a9fe76766c",
      "firstName": "rainforestqa99",
      "lastName": ""
    },
    "socialApiId": "2",
    "systemInfo": {
      "defaultToLastUsedEnvironment": true
    },
    "type": "registered"
  }, {
    "_id": ObjectId("57eb1ab9d038e29c4607d53e"),
    "counts": {
      "followers": 0,
      "following": 0,
      "topics": 0,
      "likes": 0
    },
    "isExempt": false,
    "lastLoginTimezoneOffset": 420,
    "meta": {
      "createdAt": new Date("2016-09-28T01:19:53.824Z"),
      "modifiedAt": new Date("2016-09-28T01:19:53.824Z"),
      "tags": null,
      "views": null,
      "votes": null,
      "likes": 0
    },
    "onlineStatus": "online",
    "profile": {
      "nickname": "rainforestqa22",
      "hash": "b444bc3497f76402a8767dee83da7908",
      "firstName": "rainforestqa22",
      "lastName": ""
    },
    "socialApiId": "3",
    "systemInfo": {
      "defaultToLastUsedEnvironment": true
    },
    "type": "registered"
  }],
  "jCredentialDatas": [{
    "identifier": "5afc6eb4ab15c7ebabe6d1dab2291f66",
    "meta": {
      "access_key": process.env.KONFIG_AWSKEYS_KODINGDEV_MASTER_ACCESSKEYID,
      "secret_key": process.env.KONFIG_AWSKEYS_KODINGDEV_MASTER_SECRETACCESSKEY,
      "region": "us-west-1"
    },
    "originId": ObjectId("57eb1227d038e29c4607d483"),
    "_id": ObjectId("580e2c4fcaaf6b8603ee548e")
  }, {
    "identifier": "f69ffb6b46893836adc1badb13b9f827",
    "meta": {
      "access_key": process.env.KONFIG_AWSKEYS_KODINGDEV_MASTER_ACCESSKEYID,
      "secret_key": process.env.KONFIG_AWSKEYS_KODINGDEV_MASTER_SECRETACCESSKEY,
      "region": "us-west-1"
    },
    "originId": ObjectId("57eb1ab9d038e29c4607d53e"),
    "_id": ObjectId("58244b42acd77bee02e61b0b")
  }],
  "jCredentials": [{
    "meta": {
      "createdAt": new Date("2016-10-24T15:44:15.743Z"),
      "modifiedAt": new Date("2016-10-24T15:44:15.743Z"),
      "tags": null,
      "views": null,
      "votes": null,
      "likes": 0
    },
    "verified": true,
    "accessLevel": "private",
    "provider": "aws",
    "title": "rainforestqa99's AWS keys",
    "identifier": "5afc6eb4ab15c7ebabe6d1dab2291f66",
    "originId": ObjectId("57eb1227d038e29c4607d483"),
    "_id": ObjectId("580e2c4fcaaf6b8603ee548f")
  }, {
    "meta": {
      "createdAt": new Date("2016-11-10T10:26:10.635Z"),
      "modifiedAt": new Date("2016-11-10T10:26:10.635Z"),
      "tags": null,
      "views": null,
      "votes": null,
      "likes": 0
    },
    "verified": true,
    "accessLevel": "private",
    "provider": "aws",
    "title": "RainforestQATeam2 AWS Keys",
    "identifier": "f69ffb6b46893836adc1badb13b9f827",
    "originId": ObjectId("57eb1ab9d038e29c4607d53e"),
    "_id": ObjectId("58244b42acd77bee02e61b0c")
  }],
  "jNames": [{
    "name": "rainforestqa99",
    "slugs": [{
      "slug": "rainforestqa99",
      "constructorName": "JUser",
      "usedAsPath": "username",
      "collectionName": "jUsers"
    }],
    "_id": ObjectId("57eb1227d038e29c4607d481")
  }, {
    "name": "rainforestqa22",
    "slugs": [{
      "slug": "rainforestqa22",
      "constructorName": "JUser",
      "usedAsPath": "username",
      "collectionName": "jUsers"
    }],
    "_id": ObjectId("57eb1ab9d038e29c4607d53c")
  }],
  "jUsers": [{
    "_id": ObjectId("57eb1227d038e29c4607d482"),
    "email": "rainforestqa99@koding.com",
    "emailFrequency": {
      "global": true,
      "daily": false,
      "privateMessage": true,
      "followActions": false,
      "comment": true,
      "likeActivities": false,
      "groupInvite": true,
      "groupRequest": true,
      "groupApproved": true,
      "groupJoined": true,
      "groupLeft": false,
      "mention": true,
      "marketing": false
    },
    "lastLoginDate": new Date("2016-11-10T10:21:44.468Z"),
    "onlineStatus": {
      "actual": "online"
    },
    "password": "5365f21ccaa6cc50b5773a82471aed4712e826e8",
    "passwordStatus": "valid",
    "registeredAt": new Date("2016-09-28T00:43:19.794Z"),
    "registeredFrom": {
      "country": "US",
      "ip": "208.72.139.54",
      "region": "CA"
    },
    "salt": "038afa417698f7061de2ef1d238493e2",
    "sanitizedEmail": "rainforestqa99@koding.com",
    "sshKeys": [],
    "status": "confirmed",
    "uid": null,
    "username": "rainforestqa99"
  }, {
    "_id": ObjectId("57eb1ab9d038e29c4607d53d"),
    "email": "rainforestqa22@koding.com",
    "emailFrequency": {
      "global": true,
      "daily": false,
      "privateMessage": true,
      "followActions": false,
      "comment": true,
      "likeActivities": false,
      "groupInvite": true,
      "groupRequest": true,
      "groupApproved": true,
      "groupJoined": true,
      "groupLeft": false,
      "mention": true,
      "marketing": false
    },
    "lastLoginDate": new Date("2016-11-10T10:24:14.990Z"),
    "onlineStatus": {
      "actual": "online"
    },
    "password": "47b3e28ae0daf9e218092756077d1f1a570a8f58",
    "passwordStatus": "valid",
    "registeredAt": new Date("2016-09-28T01:19:53.821Z"),
    "registeredFrom": {
      "country": "US",
      "ip": "208.72.139.54",
      "region": "CA"
    },
    "salt": "00344ea70973d10abcf77ab523488838",
    "sanitizedEmail": "rainforestqa22@koding.com",
    "sshKeys": [],
    "status": "confirmed",
    "uid": null,
    "username": "rainforestqa22"
  }],
  "relationships": [{
    "data": {},
    "timestamp": new Date("2016-09-28T00:43:19.798Z"),
    "targetId": ObjectId("57eb1227d038e29c4607d483"),
    "targetName": "JAccount",
    "sourceId": ObjectId("57eb1227d038e29c4607d482"),
    "sourceName": "JUser",
    "as": "owner",
    "_id": ObjectId("57eb1227d038e29c4607d484")
  }, {
    "data": {},
    "timestamp": new Date("2016-09-28T01:19:53.825Z"),
    "targetId": ObjectId("57eb1ab9d038e29c4607d53e"),
    "targetName": "JAccount",
    "sourceId": ObjectId("57eb1ab9d038e29c4607d53d"),
    "sourceName": "JUser",
    "as": "owner",
    "_id": ObjectId("57eb1ab9d038e29c4607d53f")
  }, {
    "data": {},
    "timestamp": new Date("2016-10-24T15:44:15.745Z"),
    "targetId": ObjectId("580e2c4fcaaf6b8603ee548f"),
    "targetName": "JCredential",
    "sourceId": ObjectId("57eb1227d038e29c4607d483"),
    "sourceName": "JAccount",
    "as": "owner",
    "_id": ObjectId("580e2c4fcaaf6b8603ee5490")
  }, {
    "data": {},
    "timestamp": new Date("2016-11-10T10:26:10.636Z"),
    "targetId": ObjectId("58244b42acd77bee02e61b0c"),
    "targetName": "JCredential",
    "sourceId": ObjectId("57eb1ab9d038e29c4607d53e"),
    "sourceName": "JAccount",
    "as": "owner",
    "_id": ObjectId("58244b42acd77bee02e61b0d")
  }]
}

exports.up = function(db, next) {
  if (process.env.CI == null)
    return next();

  async.eachOfSeries(data, function(items, collName, cb) {
    coll = db.collection(collName);
    async.eachOfLimit(items, 4, function(item, i, callback) {
      coll.findOne({
        '_id': item._id
      }, function(err, data) {
        if (!data) {
          coll.insert(item, callback);
        } else {
          callback();
        }
      });
    }, cb);
  }, next);
};

exports.down = function(db, next) {
  next();
};
