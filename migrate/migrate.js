var uid = 1000000;

var kid = db.jGroups.findOne({slug:'koding'})._id;

db.relationships.remove({
  $or: [
    {targetName:'JGroup', targetId:{$ne:kid}},
    {sourceName:'JGroup', sourceId:{$ne:kid}}
  ]
});

db.jNames.remove({
  'slugs.constructorName':'JGroup',
  name: {$ne:'koding'}
});

db.jGroups.remove({slug:{$ne:'koding'}});

db.jVMs.drop();

db.jUsers
  .find({}, {_id:1, username:1})
  .toArray().forEach(function ( u ) {
    db.jUsers.update(u, {$set:{uid:uid++}});
    db.jVMs.save({
      users:  [{id:u._id, sudo:true, owner:true}],
      groups: [{id:kid}],
      name:   'koding~'+u.username
    });
  });

db.counters.update({_id:'uid'},{$set:{seq:uid}});