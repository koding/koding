// this is sample migration file, does nothing
//
// We are using "mongodb-migrate" for our migration purposes
// ```
// Commands:
//   create [filename] : create new migration file under ./workers/migrations (ids will increase by 5)
//   up                : apply all available migrations
//   down [id]         : roll back to id (if not given roll back all migrations)
//
// ```
//
// ``` ./run mongomigrate create sample_migration```
//
// Migration settings will be persisted under "migrations" collection.
var mongodb = require('mongodb');

exports.up = function(db, next){
  var env = process.env.KONFIG_ENVIRONMENT;
  if (env !== "dev" && env !== "default") {
    return next();
  }

  coll = db.collection('jAccount');
  coll.find({ 'profile.nickname': 'admin' }, next);
};

exports.down = function(db, next){
  coll = db.collection('jAccount')
  coll.find({ 'profile.nickname': 'admin' }, next);
};
