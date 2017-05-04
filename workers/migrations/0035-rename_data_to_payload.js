var mongodb = require('mongodb');

exports.up = function(db, next){
  db.collection("jGroupDatas").updateMany({}, { $rename: { "data": "payload" } }, next);
};


exports.down = function(db, next){
    next();
};
