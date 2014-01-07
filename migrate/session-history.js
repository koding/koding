print("Add JSessionHistory entries for users who logged in January");

var query = {
  "lastLoginDate":{"$gte":new Date("01/01/2014")},
  "username" : {"$not" : /guest/ }
}

var count = db.jUsers.count(query);

print("Found " + count + " users who logged in January");

db.jUsers.find(query).forEach(function(user) {
  print(user.username, user.lastLoginDate);

  db.jSessionHistories.insert({username:user.username, createdAt:user.lastLoginDate})
});
