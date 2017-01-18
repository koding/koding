
var mongodb = require('mongodb');

exports.up = function(db, next){
  var index = {
    "name": "groupName_originId_slug",
    "key": {
      "slug": 1,
      "group": 1,
      "originId": 1
    },
    "ns": "koding.jStackTemplates",
    "unique": true
  }
  db.ensureIndex("jStackTemplates", index.key, index, next);
};

exports.down = function(db, next){
  next();
};
