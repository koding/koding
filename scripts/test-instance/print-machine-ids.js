db.jMachines.find({'status.state': {$ne: 'NotInitialized'}})
  .forEach(function(doc) {
    print(doc._id.valueOf())
  });
