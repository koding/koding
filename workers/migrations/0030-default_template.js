
var mongodb = require('mongodb');
var ObjectId = mongodb.ObjectID;

exports.up = function(db, next){
  var defaultTemplateId = ObjectId("53925a609b76835748c0c4fd");
  db.collection("jStackTemplates").update(
    { _id: defaultTemplateId },
    {
      $set: { "machines.0.provider": "aws" }
    },
    next
  );
};

exports.down = function(db, next){
  next();
};
