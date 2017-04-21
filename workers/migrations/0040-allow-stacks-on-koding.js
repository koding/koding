
var mongodb = require('mongodb');

exports.up = function(db, next){
    db.collection("jGroups").update({"slug":"koding"}, { $set: { "customize.membersCanCreateStacks": true } }, next);
};

exports.down = function(db, next){
    next();
};
