print('Adding counts.followers field to JAccounts.');
var count = db.jAccounts.count({"counts.followers":{"$exists":false}})
print('Found ' + count + ' users with no counts.followers fields in them.')

db.jAccounts.find({"counts.followers":{"$exists":false}}).toArray().forEach(function(n) {
  var followerCount = db.relationships.count({
    sourceId:n._id,
    as:"follower"
  })

  db.jAccounts.update(n, {
    $set: { "counts.followers": followerCount}
  })
})

print('Successfully completed.');
