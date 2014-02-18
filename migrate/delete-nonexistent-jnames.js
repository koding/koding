rs.slaveOk();

var query = {
  name  : {$not : /guest-/ },
  slugs : {$elemMatch: {usedAsPath:"username"}}
};

var count = db.jNames.find(query).count();
print(count + " jNames found.")

var notFoundUsers = 0;

db.jNames.find(query).forEach(function(name) {
  var username = name.name;
  var user = db.jUsers.findOne({ username: username });

  if (!user) {
    notFoundUsers++
    db.jNames.remove({ username: username });
    print("Removed " + username + " from jNames since no user found.")
  }
});

print(notFoundUsers + " not found users removed.");
