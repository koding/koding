db.jVMs.find().forEach(function(vm) {
    var hostnameAlias, rel, vmUser;

    hostnameAlias = vm.hostnameAlias;
    vmUser = vm.users.filter(function(u) {
      return u.owner === true;
    });
    if (!vmUser) {
      return;
    }
    rel = db.relationships.findOne({
      targetName: "JAccount",
      sourceId: vmUser[0].id,
      sourceName: "JUser",
      as: "owner"
    });
    return db.jDomains.find({
      hostnameAlias: {
        $in: [vm.hostnameAlias]
      }
    }).forEach(function(domain) {
      var domainRelCount, relSelector;

      relSelector = {
        targetName: "JDomain",
        targetId: domain._id,
        sourceName: "JAccount",
        sourceId: rel.targetId,
        as: "owner"
      };
      domainRelCount = db.relationships.count(relSelector);
      if (domainRelCount === 0) {
        relSelector.timestamp = new Date();
        return db.relationships.insert(relSelector);
      }
    });
  });