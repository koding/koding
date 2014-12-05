db.jUsers.find().forEach(function(user){
  db.jUsers.update(user, {
    $set: { "emailFrequency.marketing": true}
  })

  print("Updated user " + user.username)
})
