print("\nWARNING: THIS SHOULDN'T BE RUN IN PRODUCTION\n");
print("Starting email cleaner...\n");

print("Dropping jMails\n");
db.jMails.drop();

var query = {
  "username" : {"$not":/guest/}
}

print("Resetting emails for users");

db.jUsers.find(query).forEach(function(user){
  var email = user.username+"@koding.com"
  db.jUsers.update({_id: user._id}, {$set: {email:email}});

  print("Setting "+user.username+"'s email to "+email);
});

print("\nAll done...exiting")
